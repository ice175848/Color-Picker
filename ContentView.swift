import SwiftUI

struct ContentView: View {
    @State private var image: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var colorCode: String = "點選圖片來獲取色碼"
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    @State private var tappedColor: UIColor = .clear
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { geometry in
                            ZStack {
                                if showMagnifier {
                                    MagnifierView(color: tappedColor)
                                        .position(magnifierPosition)
                                        .offset(x: 0, y: -100)
                                }
                            }
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                if let color = getColor(at: location, in: image) {
                                    tappedColor = color
                                    magnifierPosition = location
                                    showMagnifier = true
                                    colorCode = "RGB: \(color.toRGBString()),\n CMYK: \(color.toCMYKString())"
                                }
                            }
                            .onEnded { value in
                                let location = value.location
                                if let color = getColor(at: location, in: image) {
                                    tappedColor = color
                                    magnifierPosition = location
                                    showMagnifier = true
                                    colorCode = "RGB: \(color.toRGBString()),\n CMYK: \(color.toCMYKString())"
                                }
                            }
                    )
            } else {
                Text("點選下方按鈕來拍照或選擇圖片")
            }
            Text(colorCode)
                .padding()
            Button(action: {
                showingImagePicker = true
            }) {
                Text("選擇圖片")
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    func getColor(at location: CGPoint, in image: UIImage) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }
        let pixelData = cgImage.dataProvider!.data
        let data = CFDataGetBytePtr(pixelData)
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let viewWidth = UIScreen.main.bounds.width
        let viewHeight = viewWidth * (imageHeight / imageWidth)
        
        let x = Int(location.x * imageWidth / viewWidth)
        let y = Int(location.y * imageHeight / viewHeight)
        
        let pixelInfo = ((Int(imageWidth) * y) + x) * 4

        let r = CGFloat(data![pixelInfo]) / 255.0
        let g = CGFloat(data![pixelInfo+1]) / 255.0
        let b = CGFloat(data![pixelInfo+2]) / 255.0
        let a = CGFloat(data![pixelInfo+3]) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

struct MagnifierView: View {
    var color: UIColor
    
    var body: some View {
        Circle()
            .fill(Color(color))
            .frame(width: 100, height: 100)
            .overlay(
                Circle().stroke(Color.white, lineWidth: 4)
            )
            .shadow(radius: 10)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

extension UIColor {
    func toRGBString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "R: %d, G: %d, B: %d", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    func toCMYKString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let c = 1 - r
        let m = 1 - g
        let y = 1 - b
        let k = min(c, m, y)
        
        let cmykC = (c - k) / (1 - k)
        let cmykM = (m - k) / (1 - k)
        let cmykY = (y - k) / (1 - k)
        let cmykK = k
        
        return String(format: "C: %.2f, M: %.2f, Y: %.2f, K: %.2f", cmykC, cmykM, cmykY, cmykK)
    }
}
