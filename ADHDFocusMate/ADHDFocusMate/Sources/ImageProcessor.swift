import AppKit

/// Utility for preprocessing images before sending to Gemini
/// Handles downscaling and compression to minimize token usage
struct ImageProcessor {

    // MARK: - Configuration

    /// Default maximum dimension for downscaled images (384px keeps tokens low)
    static let defaultMaxDimension: Int = 384

    /// Default JPEG quality (0.7 is a good balance of size vs quality)
    static let defaultJPEGQuality: CGFloat = 0.7

    // MARK: - Public Methods

    /// Downscale image to fit within max dimension while preserving aspect ratio
    /// - Parameters:
    ///   - image: The source NSImage to downscale
    ///   - maxDimension: Maximum width or height in pixels
    /// - Returns: Downscaled NSImage
    static func downscale(_ image: NSImage, maxDimension: Int = defaultMaxDimension) -> NSImage {
        let originalSize = image.size

        // Calculate scale factor
        let maxOriginalDimension = max(originalSize.width, originalSize.height)

        // If already smaller than target, return original
        guard maxOriginalDimension > CGFloat(maxDimension) else {
            return image
        }

        let scaleFactor = CGFloat(maxDimension) / maxOriginalDimension
        let newSize = NSSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )

        // Create new downscaled image
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )

        newImage.unlockFocus()
        return newImage
    }

    /// Compress image to JPEG data
    /// - Parameters:
    ///   - image: The NSImage to compress
    ///   - quality: JPEG quality (0.0-1.0)
    /// - Returns: Compressed JPEG data, or nil if compression fails
    static func compressToJPEG(_ image: NSImage, quality: CGFloat = defaultJPEGQuality) -> Data? {
        guard let tiffData = image.tiffRepresentation,
            let bitmapRep = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmapRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }

    /// Process image for Gemini: downscale and compress
    /// - Parameters:
    ///   - image: The source NSImage
    ///   - maxDimension: Maximum dimension for downscaling
    ///   - quality: JPEG compression quality
    /// - Returns: Compressed JPEG data ready for Gemini, or nil on failure
    static func processForClassification(
        _ image: NSImage,
        maxDimension: Int = defaultMaxDimension,
        quality: CGFloat = defaultJPEGQuality
    ) -> Data? {
        let downscaled = downscale(image, maxDimension: maxDimension)
        return compressToJPEG(downscaled, quality: quality)
    }

    /// Estimate token count for image data
    /// Based on Gemini 2.x token calculation rules:
    /// - Images are resized to fit 768x768 before tokenization
    /// - Approximately 258 tokens for images <= 384px
    /// - Scales up for larger images
    /// - Parameters:
    ///   - imageData: The JPEG image data
    /// - Returns: Estimated token count
    static func estimateTokenCount(for imageData: Data) -> Int {
        // Get image dimensions from data
        guard let image = NSImage(data: imageData) else {
            return 258  // Default minimum
        }

        let size = image.size
        let maxDim = max(size.width, size.height)

        // Gemini token estimation based on image size
        // Small images (<=384px): ~258 tokens
        // Medium images (<=768px): ~516 tokens
        // Large images (>768px): ~774+ tokens
        if maxDim <= 384 {
            return 258
        } else if maxDim <= 768 {
            return 516
        } else {
            return 774
        }
    }

    /// Get image dimensions from data
    /// - Parameter imageData: Image data
    /// - Returns: Tuple of (width, height) or nil if invalid
    static func getImageDimensions(from imageData: Data) -> (width: Int, height: Int)? {
        guard let image = NSImage(data: imageData) else {
            return nil
        }
        return (Int(image.size.width), Int(image.size.height))
    }
}
