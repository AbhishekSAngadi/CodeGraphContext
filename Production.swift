import SwiftUI

// MARK: - Model
struct User: Identifiable, Codable {
    let id: Int
    let login: String
    let avatar_url: String
}

// MARK: - ViewModel (MVVM)
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func fetchUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "https://api.github.com/users") else {
            errorMessage = "Invalid URL"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedUsers = try JSONDecoder().decode([User].self, from: data)
            self.users = decodedUsers
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
        }
    }
}

// MARK: - View
struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading users...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    List(viewModel.users) { user in
                        HStack {
                            AsyncImage(url: URL(string: user.avatar_url)) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                            Text(user.login).font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("GitHub Users")
            .task {
                await viewModel.fetchUsers()
            }
        }
    }
}

// MARK: - App Entry
@main
struct HacktoberfestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
