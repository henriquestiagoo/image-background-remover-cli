import Foundation

enum Error: Swift.Error {
    case invalidImageData
    case failedToCreateCIImage
    case failedToRenderCGImage
}
