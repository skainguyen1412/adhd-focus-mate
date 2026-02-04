import AppKit
import Testing

@testable import ADHDFocusMate

// MARK: - ImageProcessor Tests

struct ImageProcessorTests {

    // MARK: - Downscaling Tests

    @Test func downscale_imageAlreadySmall_returnsOriginalSize() async throws {
        let smallImage = createTestImage(width: 100, height: 100)

        let result = ImageProcessor.downscale(smallImage, maxDimension: 384)

        #expect(result.size.width == 100)
        #expect(result.size.height == 100)
    }

    @Test func downscale_landscapeImage_scalesCorrectly() async throws {
        let largeImage = createTestImage(width: 1920, height: 1080)

        let result = ImageProcessor.downscale(largeImage, maxDimension: 384)

        #expect(result.size.width == 384)
        #expect(result.size.height == 216)
    }

    @Test func downscale_portraitImage_scalesCorrectly() async throws {
        let largeImage = createTestImage(width: 1080, height: 1920)

        let result = ImageProcessor.downscale(largeImage, maxDimension: 384)

        #expect(result.size.height == 384)
        #expect(result.size.width == 216)
    }

    @Test func downscale_squareImage_scalesCorrectly() async throws {
        let largeImage = createTestImage(width: 2000, height: 2000)

        let result = ImageProcessor.downscale(largeImage, maxDimension: 384)

        #expect(result.size.width == 384)
        #expect(result.size.height == 384)
    }

    @Test func downscale_customMaxDimension_works() async throws {
        let image = createTestImage(width: 1000, height: 500)

        let result = ImageProcessor.downscale(image, maxDimension: 200)

        #expect(result.size.width == 200)
        #expect(result.size.height == 100)
    }

    // MARK: - JPEG Compression Tests

    @Test func compressToJPEG_validImage_returnsData() async throws {
        let image = createTestImage(width: 100, height: 100)

        let result = ImageProcessor.compressToJPEG(image)

        #expect(result != nil)
        #expect(result!.count > 0)
    }

    @Test func compressToJPEG_differentQuality_affectsSize() async throws {
        let image = createTestImage(width: 200, height: 200)

        let lowQuality = ImageProcessor.compressToJPEG(image, quality: 0.3)
        let highQuality = ImageProcessor.compressToJPEG(image, quality: 0.9)

        #expect(lowQuality != nil)
        #expect(highQuality != nil)
        #expect(lowQuality!.count <= highQuality!.count)
    }

    // MARK: - Process For Classification Tests

    @Test func processForClassification_largeImage_returnsSmallJPEG() async throws {
        let largeImage = createTestImage(width: 2560, height: 1440)

        let result = ImageProcessor.processForClassification(largeImage)

        #expect(result != nil)

        if let dims = ImageProcessor.getImageDimensions(from: result!) {
            #expect(dims.width <= 384)
            #expect(dims.height <= 384)
        }
    }

    // MARK: - Token Estimation Tests

    @Test func estimateTokenCount_smallImage_returns258() async throws {
        let smallImage = createTestImage(width: 300, height: 200)
        guard let data = ImageProcessor.compressToJPEG(smallImage) else {
            Issue.record("Failed to create test image data")
            return
        }

        let tokens = ImageProcessor.estimateTokenCount(for: data)

        #expect(tokens == 258)
    }

    @Test func estimateTokenCount_mediumImage_returns516() async throws {
        let mediumImage = createTestImage(width: 500, height: 400)
        guard let data = ImageProcessor.compressToJPEG(mediumImage) else {
            Issue.record("Failed to create test image data")
            return
        }

        let tokens = ImageProcessor.estimateTokenCount(for: data)

        #expect(tokens == 516)
    }

    // MARK: - Helpers

    private func createTestImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        return image
    }
}
