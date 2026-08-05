import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.secondaryBackground.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                } else if viewModel.posts.isEmpty {
                    Text("No hay novedades recientes.")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                PostCardView(post: post)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.loadPosts()
                    }
                }
            }
            .navigationTitle("Muro Corporativo")
            .onAppear {
                viewModel.loadPosts()
            }
        }
    }
}

struct PostCardView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(post.type.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForType(post.type).opacity(0.2))
                    .foregroundColor(colorForType(post.type))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(post.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            
            Text(post.content)
                .font(Typography.body())
                .foregroundColor(ColorTheme.textPrimary)
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(post.authorName)
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)
            }
        }
        .padding()
        .background(ColorTheme.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func colorForType(_ type: PostType) -> Color {
        switch type {
        case .alert: return Color.red
        case .news: return Color.blue
        case .event: return Color.orange
        case .birthday: return Color.pink
        }
    }
}
