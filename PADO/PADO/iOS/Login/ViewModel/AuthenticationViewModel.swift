//
//  AuthenticationViewModel.swift
//  PADO
//
//  Created by 강치우 on 1/3/24.
//

import Firebase
import FirebaseStorage
import PhotosUI
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    @Published var nameID = ""
    @Published var year = ""
    @Published var phoneNumber = ""
    
    @Published var otpText = ""
    
    @Published var isLoading: Bool = false
    @Published var verificationCode: String = ""
    
    @Published var errorMessage = ""
    @Published var showAlert = false
    @Published var isExisted = false
    
    // 탭바 이동관련 변수
    @Published var showTab: Int = 0
    
    // 세팅 관련 뷰 이동 변수
    @Published var showingProfileView: Bool = false
    @Published var showingEditProfile: Bool = false
    @Published var showingEditBackProfile: Bool = false
    
    // MARK: - SettingProfile
    @Published var username = ""
    @Published var instaAddress = ""
    @Published var tiktokAddress = ""
    @Published var imagePick: Bool = false
    @Published var backimagePick: Bool = false
    @Published var changedValue: Bool = false
    @Published var showProfileModal: Bool = false
    @Published var selectedFilter: FeedFilter = .today
    
    // MARK: - SettingNoti
    @Published var alertAccept = ""
    
    @Published var birthDate = Date() {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy년 MM월 dd일"
            year = dateFormatter.string(from: birthDate)
        }
    }
    
    // 프로필 사진 변경 값 저장
    @Published var userSelectImage: Image?
    @Published var uiImage: UIImage?
    
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            Task {
                do {
                    let (loadedUIImage, loadedSwiftUIImage) = try await UpdateImageUrl.shared.loadImage(selectedItem: selectedItem)
                    self.uiImage = loadedUIImage
                    self.userSelectImage = loadedSwiftUIImage
                } catch {
                    print("이미지 로드 중 오류 발생: \(error)")
                }
            }
        }
    }
    
    // 배경화면 변경값 저장
    @Published var backSelectImage: Image?
    @Published var backuiImage: UIImage?
    
    @Published var selectedBackgroundItem: PhotosPickerItem? {
        didSet {
            Task {
                do {
                    let (loadedUIImage, loadedSwiftUIImage) = try await UpdateImageUrl.shared.loadImage(selectedItem: selectedBackgroundItem)
                    self.backuiImage = loadedUIImage
                    self.backSelectImage = loadedSwiftUIImage
                } catch {
                    print("이미지 로드 중 오류 발생: \(error)")
                }
            }
        }
    }
    
    @Published var authResult: AuthDataResult?
    
    @Published var currentUser: User?
    
    // MARK: - Profile SNS
    // SNS 주소의 등록 여부를 확인
    var isAnySocialAccountRegistered: Bool {
        !(currentUser?.instaAddress ?? "").isEmpty || !(currentUser?.tiktokAddress ?? "").isEmpty
    }
    
    var areBothSocialAccountsRegistered: Bool {
        !(currentUser?.instaAddress ?? "").isEmpty && !(currentUser?.tiktokAddress ?? "").isEmpty
    }
    
    // MARK: - 인증 관련
    func sendOtp() async {
        // OTP 발송
        do {
            isLoading = true
            let result = try await PhoneAuthProvider.provider().verifyPhoneNumber("+82\(phoneNumber)", uiDelegate: nil) // 사용한 가능한 번호인지
            verificationCode = result
            isLoading = false
        } catch {
            handleError(error: error)
        }
    }
    
    func verifyOtp() async -> Bool {
        // Otp 검증
        guard !otpText.isEmpty else { return false }
        isLoading = true
        do {
            let result = try await signInWithCredential()
            authResult = result
            
            isLoading = false
            return true
        } catch {
            handleError(error: error)
            isLoading = false
            return false
        }
    }
    
    private func signInWithCredential() async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationCode, verificationCode: otpText)
        print(credential)
        return try await Auth.auth().signIn(with: credential)
    }
    
    func signUpUser() async {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let initialUserData = [
            "username": "",
            "lowercasedName": "",
            "id": userId,
            "nameID": nameID,
            "date": year,
            "phoneNumber": "+82\(phoneNumber)",
            "fcmToken": userToken,
            "alertAccept": "",
            "instaAddress": "",
            "tiktokAddress": ""
        ]
        userNameID = nameID
        await createUserData(nameID, data: initialUserData)
    }
    
    func createUserData(_ nameID: String, data: [String: Any]) async {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await Firestore.firestore().collection("users").document(nameID).setData(data)
            
            userNameID = nameID
            currentUser = User(
                id: userId,
                username: "",
                lowercasedName: "",
                nameID: nameID,
                date: year,
                phoneNumber: "+82\(phoneNumber)",
                fcmToken: userToken,
                alertAccept: "",
                instaAddress: "",
                tiktokAddress: ""
            )
           
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
        }
    }
    
    func checkPhoneNumberExists(phoneNumber: String) async -> Bool {
        // 전화번호 중복 확인
        let userDB = Firestore.firestore().collection("users")
        let query = userDB.whereField("phoneNumber", isEqualTo: phoneNumber)
        
        do {
            let querySnapshot = try await query.getDocuments()
            print("documets: \(querySnapshot.documents)")
            if !querySnapshot.documents.isEmpty {
                return true
            } else {
                return false
            }
        } catch {
            print("Error: \(error)")
            return false
        }
    }
    
    func checkForDuplicateID() async -> Bool {
        // ID 중복 확인
        let usersCollection = Firestore.firestore().collection("users")
        let query = usersCollection.whereField("nameID", isEqualTo: nameID.lowercased())
        
        do {
            let querySnapshot = try await query.getDocuments()
            return !querySnapshot.documents.isEmpty
        } catch {
            print("Error checking for duplicate ID: \(error)")
            return true
        }
    }
    
    
    // MARK: - 사용자 데이터 관리
    func initializeUser() async {
        // 사용자 초기화

        guard Auth.auth().currentUser?.uid != nil else { return }
        await fetchUser()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            
            nameID = ""
            userNameID = ""
            year = ""
            phoneNumber = ""
            otpText = ""
            verificationCode = ""
            instaAddress = ""
            tiktokAddress = ""
            showAlert = false
            isExisted = false
            currentUser = nil
            selectedFilter = .today
            userFollowingIDs.removeAll()
            showTab = 0
            
            print("dd")
            print(String(describing: Auth.auth().currentUser?.uid))
            print("dd")
            print(String(describing: currentUser))
        } catch {
            print("로그아웃 오류: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        // 계정 삭제
        let db = Firestore.firestore()
        let storageRef = Storage.storage().reference()
        
        let postQuery = db.collection("post").whereField("ownerUid", isEqualTo: nameID)
        
        // Firestore의 `post` 컬렉션에서 사용자의 게시물 삭제
        do {
            let querySnapshot = try await postQuery.getDocuments()
            for document in querySnapshot.documents {
                await DeletePost.shared.deletePost(postID: document.documentID)
            }
        
        } catch {
            print("Error removing posts: \(error.localizedDescription)")
        }
        
        // user 컬렉션 삭제
        do {
            let sendPostQuery = try await db.collection("users").document(nameID).collection("sendpost").getDocuments()
            
            let myPostQuery = try await db.collection("users").document(nameID).collection("mypost").getDocuments()
            
            let followingQuery = try await db.collection("users").document(nameID).collection("following").getDocuments()
            
            let followerQuery = try await db.collection("users").document(nameID).collection("follower").getDocuments()
            
            let surferQuery = try await db.collection("users").document(nameID).collection("surfer").getDocuments()
            
            let notiQuery = try await db.collection("users").document(nameID).collection("notifications").getDocuments()
            
            let messageQuery = try await db.collection("users").document(nameID).collection("message").getDocuments()
            
            let highlightQuery = try await db.collection("users").document(nameID).collection("highlight").getDocuments()
            
            for document in sendPostQuery.documents {
                try await db.collection("users").document(nameID).collection("sendpost").document(document.documentID).delete()
            }
            
            for document in myPostQuery.documents {
                try await db.collection("users").document(nameID).collection("mypost").document(document.documentID).delete()
            }
            
            for document in followingQuery.documents {
                await UpdateFollowData.shared.directUnfollowUser(id: document.documentID)
            }
            
            for document in followerQuery.documents {
                await UpdateFollowData.shared.removeFollower(id: document.documentID)
            }
        
            for document in surferQuery.documents {
                await UpdateFollowData.shared.removeSurfer(id: document.documentID)
            }
            
            for document in notiQuery.documents {
                try await db.collection("users").document(nameID).collection("notifications").document(document.documentID).delete()
            }
            
            for document in messageQuery.documents {
                try await db.collection("users").document(nameID).collection("message").document(document.documentID).delete()
            }
            
            for document in highlightQuery.documents {
                try await db.collection("users").document(nameID).collection("highlight").document(document.documentID).delete()
            }
            
            try await db.collection("users").document(nameID).delete()
            
        } catch {
            print("Error removing document: \(error.localizedDescription)")
        }
        
        // Firebase Storage에서 사용자의 'post/' 경로에 있는 모든 이미지 삭제
        let userPostsRef = storageRef.child("post/\(nameID)")
        let userProfliesRef = storageRef.child("profile_image/\(nameID)")
        let userBackRef = storageRef.child("back_image/\(nameID)")
        do {
            let listResult = try await userPostsRef.listAll()
            let profileListResult = try await userProfliesRef.listAll()
            let backgroundListResult = try await userBackRef.listAll()
            for item in listResult.items {
                // 각 항목 삭제
                try await item.delete()
            }
            
            for item in profileListResult.items {
                try await item.delete()
            }
            
            for item in backgroundListResult.items {
                try await item.delete()
            }
            
        } catch {
            print("Error removing posts from storage: \(error.localizedDescription)")
        }
        
        userNameID = ""
        nameID = ""
        year = ""
        phoneNumber = ""
        otpText = ""
        verificationCode = ""
        instaAddress = ""
        tiktokAddress = ""
        showAlert = false
        isExisted = false
        currentUser = nil
        selectedFilter = .today
        userFollowingIDs.removeAll()
        showTab = 0
    }
    
    // MARK: - Firestore 쿼리 처리
    
    func fetchUIDByPhoneNumber(phoneNumber: String) async {
        // 전화번호로 Firestore
        let usersCollection = Firestore.firestore().collection("users")
        let query = usersCollection.whereField("phoneNumber", isEqualTo: phoneNumber)
        
        do {
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                self.nameID = document.documentID
                userNameID = self.nameID
            }
            
        } catch {
            print("Error fetching user by phone number: (error)")
        }
    }
    
    func fetchUser() async {
        // 사용자 데이터 불러오기
        
        do {
            try await Firestore.firestore().collection("users").document(nameID).updateData([
                "fcmToken": userToken,
            ])
            
            let snapshot = try await Firestore.firestore().collection("users").document(nameID).getDocument()
            print("nameID: \(nameID)")
            print("Snapshot: \(String(describing: snapshot.data()))")
            
            guard let user = try? snapshot.data(as: User.self) else {
                print("Error: User data could not be decoded")
                return
            }
            currentUser = user
            print("Current User: \(String(describing: currentUser))")
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    // MARK: - 오류 처리
    func handleError(error: Error) {
        // 오류 처리
        errorMessage = error.localizedDescription
        showAlert.toggle()
        isLoading = false
    }
    // MARK: - SettingProfileView
    func profileSaveData() async {
        Task {
            // 버튼이 활성화된 경우 실행할 로직
            try await UpdateUserData.shared.updateUserData(initialUserData: ["username": username,
                                                                             "lowercasedName": username.lowercased(),
                                                                             "instaAddress": instaAddress,
                                                                             "tiktokAddress": tiktokAddress])
            currentUser?.username = username
            currentUser?.lowercasedName = username.lowercased()
            currentUser?.instaAddress = instaAddress
            currentUser?.tiktokAddress = tiktokAddress
            
            
            if imagePick && backimagePick {
                let returnString = try await UpdateImageUrl.shared.updateImageUserData(uiImage: uiImage,
                                                                                       storageTypeInput: .user,
                                                                                       documentid: "",
                                                                                       imageQuality: .middleforProfile,
                                                                                       surfingID: "")
                currentUser?.profileImageUrl = returnString
                
                let returnBackString = try await UpdateImageUrl.shared.updateImageUserData(uiImage: backuiImage,
                                                                                           storageTypeInput: .backImage,
                                                                                           documentid: "",
                                                                                           imageQuality: .highforPost,
                                                                                           surfingID: "")
                currentUser?.backProfileImageUrl = returnBackString
            } else if imagePick {
                let returnString = try await UpdateImageUrl.shared.updateImageUserData(uiImage: uiImage,
                                                                                       storageTypeInput: .user,
                                                                                       documentid: "",
                                                                                       imageQuality: .middleforProfile,
                                                                                       surfingID: "")
                currentUser?.profileImageUrl = returnString
            } else if backimagePick {
                let returnBackString = try await UpdateImageUrl.shared.updateImageUserData(uiImage: backuiImage,
                                                                                           storageTypeInput: .backImage,
                                                                                           documentid: "",
                                                                                           imageQuality: .highforPost,
                                                                                           surfingID: "")
                currentUser?.backProfileImageUrl = returnBackString
            }
        }
    }
    
    func fetchUserProfile() {
        username = currentUser?.username ?? ""
        instaAddress = currentUser?.instaAddress ?? ""
        tiktokAddress = currentUser?.tiktokAddress ?? ""
        changedValue = false
    }
    
    func checkForChanges() {
        // 현재 데이터와 원래 데이터 비교
        let isUsernameChanged = currentUser?.username != username
        let isInstaAddressChanged = currentUser?.instaAddress != instaAddress
        let isTiktokAddressChanged = currentUser?.tiktokAddress != tiktokAddress
        
        changedValue = isUsernameChanged || isInstaAddressChanged || isTiktokAddressChanged || imagePick || backimagePick
        
    }
    
    func updateAlertAcceptance(newStatus: Bool) async {
        let alertAccept = newStatus ? "yes" : "no"
        
        do {
            try await UpdateUserData.shared.updateUserData(initialUserData: ["alertAccept": alertAccept])
        } catch {
            print("알림 설정 업데이트 중 오류 발생: \(error)")
        }
    }
    
    func fetchUserAlertAcceptance() {
        alertAccept = currentUser?.alertAccept ?? ""
    }
}
