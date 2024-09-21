import AppKit
import ArgumentParser
import Foundation
import PathKit
import Vision
import CoreImage.CIFilterBuiltins

@main
struct ImageBackgroundRemover: ParsableCommand {
    @Option(name: .shortAndLong, transform: relativePath(from:))
    var input: Path

    @Option(name: .shortAndLong, transform: relativePath(from:))
    var output: Path

    @MainActor mutating func run() throws {
        print("Running ImageBackgroundRemover CLI tool ...")

        let imageData = try input.read()
        guard let image = NSImage(data: imageData) else { throw Error.invalidImageData }
        guard let ciImage = image.asCIImage() else { throw Error.failedToCreateCIImage }

        let outputImage = try removeBackground(from: ciImage)
        guard let outputImageData = outputImage.asPNGData else { throw Error.invalidImageData }
        try output.write(outputImageData)

        print("Created new image with background removed at: \(output)")
    }

    private func removeBackground(from inputImage: CIImage) throws -> NSImage {
        guard let maskImage = createMask(from: inputImage) else { throw Error.failedToCreateCIImage }
        let outputImage = applyMask(mask: maskImage, to: inputImage)
        guard let nsImage = outputImage.asNSImage() else { throw Error.failedToRenderCGImage }
        return nsImage
    }

    private func createMask(from inputImage: CIImage) -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)

        do {
            try handler.perform([request])
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }

        return nil
    }

    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }
}
