// Usage: swift render.swift <in.svg> <out.(png|pdf)> <height> [mask]
// The width follows the SVG's aspect ratio (square icons: width == height).
// "mask" clips to the macOS app icon grid: 824px rounded rect (r=185.4) centered in 1024.
import AppKit

let args = CommandLine.arguments
guard args.count >= 4, let size = Double(args[3]) else {
  FileHandle.standardError.write("usage: render <in.svg> <out> <px> [mask]\n".data(using: .utf8)!)
  exit(2)
}
let masked = args.count > 4 && args[4] == "mask"
var svg = try String(contentsOfFile: args[1], encoding: .utf8)
svg = svg.replacingOccurrences(of: "currentColor", with: "#000000")
guard let image = NSImage(data: Data(svg.utf8)) else {
  FileHandle.standardError.write("NSImage could not load \(args[1])\n".data(using: .utf8)!)
  exit(1)
}
let out = URL(fileURLWithPath: args[2])
let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
let canvas = NSRect(x: 0, y: 0, width: (size * aspect).rounded(), height: size)

func draw(in ctx: CGContext) {
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
  if masked {
    let k = size / 1024
    let inset = 100 * k
    NSBezierPath(
      roundedRect: canvas.insetBy(dx: inset, dy: inset),
      xRadius: 185.4 * k, yRadius: 185.4 * k
    ).addClip()
  }
  image.draw(in: canvas, from: .zero, operation: .sourceOver, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()
}

if out.pathExtension == "pdf" {
  var box = canvas
  guard let ctx = CGContext(out as CFURL, mediaBox: &box, nil) else { exit(1) }
  ctx.beginPDFPage(nil)
  draw(in: ctx)
  ctx.endPDFPage()
  ctx.closePDF()
} else {
  guard
    let ctx = CGContext(
      data: nil, width: Int(canvas.width), height: Int(canvas.height), bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
  else { exit(1) }
  draw(in: ctx)
  let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
  try rep.representation(using: .png, properties: [:])!.write(to: out)
}
