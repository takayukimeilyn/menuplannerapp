import SwiftUI

struct TutorialView: View {
    @Binding var showTutorial: Bool

    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                
                Text("レシピサイトからの情報取得方法")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
            }
            VStack{
                Text("Safariでレシピサイトを開き、共有ボタンをタップします。")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Image("tutorial_1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300) // ここで幅は指定せず、高さのみを指定します
                    .clipped()
                Text("アクションを編集をタップします。")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("tutorial_2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300) // ここで幅は指定せず、高さのみを指定します
                    .clipped()
                Text("おうちごはんに連携のトグルをオンにします。")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("tutorial_3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300) // ここで幅は指定せず、高さのみを指定します
                    .clipped()
                Text("safariで登録したいレシピサイトを開き、おうちごはんに連携をタップします。レシピ名や材料が自動的にマイメニューに登録されます。")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                Image("tutorial_4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300) // ここで幅は指定せず、高さのみを指定します
                    .clipped()

                Spacer()

                Button(action: {
                    showTutorial = false
                }) {
                    Text("さあ、はじめてみましょう！")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
    }
}
