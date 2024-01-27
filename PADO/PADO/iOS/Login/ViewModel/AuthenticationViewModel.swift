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
    
    // MARK: - SettingProfile
    @Published var username = ""
    @Published var instaAddress = ""
    @Published var tiktokAddress = ""
    @Published var imagePick: Bool = false
    @Published var changedValue: Bool = false
    
    @Published var birthDate = Date() {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY년 MM월 DD일"
            year = dateFormatter.string(from: birthDate)
        }
    }
    
    
    @Published var userSelectImage: Image?
    @Published private var uiImage: UIImage?
    
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
    
    @Published var authResult: AuthDataResult?
    
    @AppStorage("userID") var userID: String = ""
    
    @Published var currentUser: User?
    
    // MARK: - 인증 관련
    func sendOtp() async {
        // OTP 발송
        do {
            isLoading = true
            let result = try await PhoneAuthProvider.provider().verifyPhoneNumber("+82\(phoneNumber)", uiDelegate: nil) // 사용한 가능한 번호인지
            print(result)
            verificationCode = result
            print(verificationCode)
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
        return try await Auth.auth().signIn(with: credential)
    }
    
    func signUpUser(user: Firebase.User?) async {
        guard let unwrappedUser = user else {
            print("Error: User is nil")
            return
        }
        
        userID = unwrappedUser.uid
        
        let initialUserData = [
            "username": "",
            "id": userID,
            "nameID": nameID,
            "date": year,
            "phoneNumber": "+82\(phoneNumber)",
            "fcmToken": userToken,
            "alertAccept": userAlertAccept,
            "instaAddress": "",
            "tiktokAddress": ""
        ]
        
        await createUserData(userID, data: initialUserData)
    }
    
    func createUserData(_ userID: String, data: [String: Any]) async {
        do {
            try await Firestore.firestore().collection("users").document(userID).setData(data)
            currentUser = User(
                id: userID,
                username: "",
                nameID: nameID,
                date: year,
                phoneNumber: "+82\(phoneNumber)",
                fcmToken: userToken,
                alertAccept: userAlertAccept,
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
        guard !userID.isEmpty else { return }
        await fetchUser()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            userID = ""
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
            
            print(userID)
            print(String(describing: currentUser))
        } catch {
            print("로그아웃 오류: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async {
        // 계정 삭제
        let db = Firestore.firestore()
        
        do {
            try await db.collection("users").document(userID).delete()
        } catch {
            print("Error removing document: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Firestore 쿼리 처리
    
    // 이 함수 필요없는거같으니 확인바람
    func fetchUIDByPhoneNumber(phoneNumber: String) async {
        // 전화번호로 Firestore
        let usersCollection = Firestore.firestore().collection("users")
        let query = usersCollection.whereField("phoneNumber", isEqualTo: phoneNumber)
        
        do {
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                self.userID = document.documentID
            }
            
        } catch {
            print("Error fetching user by phone number: (error)")
        }
    }
    
    func fetchUser() async {
        // 사용자 데이터 불러오기
        guard !userID.isEmpty else { return }
        
        do {
            try await Firestore.firestore().collection("users").document(userID).updateData([
                "fcmToken": userToken,
                "alertAccept": userAlertAccept
            ])
            
            let snapshot = try await Firestore.firestore().collection("users").document(userID).getDocument()
            print("UserID: \(userID)")
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
    
    func profileSaveData() async {
        Task {
            // 버튼이 활성화된 경우 실행할 로직
            try await UpdateUserData.shared.updateUserData(initialUserData: ["username": username,
                                                                             "instaAddress": instaAddress,
                                                                             "tiktokAddress": tiktokAddress])
            currentUser?.username = username
            currentUser?.instaAddress = instaAddress
            currentUser?.tiktokAddress = tiktokAddress
            
            let returnString = try await UpdateImageUrl.shared.updateImageUserData(uiImage: uiImage)
            currentUser?.profileImageUrl = returnString
        }
    }
    
    // MARK: - SettingProfileView
    func fetchUserProfile() {
        username = currentUser?.username ?? ""
        instaAddress = currentUser?.instaAddress ?? ""
        tiktokAddress = currentUser?.tiktokAddress ?? ""
        imagePick = false
        userSelectImage = nil
    }
    
    func checkForChanges() {
        // 현재 데이터와 원래 데이터 비교
        let isUsernameChanged = currentUser?.username != username
        let isInstaAddressChanged = currentUser?.instaAddress != instaAddress
        let isTiktokAddressChanged = currentUser?.tiktokAddress != tiktokAddress
        changedValue = isUsernameChanged || isInstaAddressChanged || isTiktokAddressChanged || imagePick
    }
    
}
