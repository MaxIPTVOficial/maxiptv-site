import Foundation
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers

// Gera a imagem de compartilhamento (Open Graph) do site: 1200×630, a medida que
// WhatsApp, Telegram, X e LinkedIn esperam.
//
// ⚠️ Existe porque, no começo, quase toda visita vem de um link colado num
// grupo — e um link "pelado", sem imagem, parece spam justamente onde a
// confiança mais importa: numa mensagem pedindo dinheiro por assinatura.
//
// Mesma marca do ícone (`MaxIPTVApple/tools/GerarIcone.swift`): fundo
// azul-escuro, "NOT" claro e "TV" âmbar (até 30/09: "M" âmbar do MAX IPTV).
//
// Uso:  swift tools/GerarOG.swift  (gera og.png na raiz do site)

func desenha(_ largura: Int, _ altura: Int, _ corpo: (CGContext) -> Void) -> CGImage? {
    guard let ctx = CGContext(data: nil, width: largura, height: altura, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    corpo(ctx)
    return ctx.makeImage()
}

func salva(_ img: CGImage, _ caminho: String) {
    let url = URL(fileURLWithPath: caminho)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

@discardableResult
func texto(_ ctx: CGContext, _ s: String, fonte: CTFont, cor: CGColor, x: CGFloat, y: CGFloat) -> CGFloat {
    let attrs: [CFString: Any] = [kCTFontAttributeName: fonte, kCTForegroundColorAttributeName: cor]
    let str = CFAttributedStringCreate(nil, s as CFString, attrs as CFDictionary)!
    let linha = CTLineCreateWithAttributedString(str)
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(linha, ctx)
    return CGFloat(CTLineGetTypographicBounds(linha, nil, nil, nil))
}

func largura(_ s: String, _ f: CTFont) -> CGFloat {
    let str = CFAttributedStringCreate(nil, s as CFString, [kCTFontAttributeName: f] as CFDictionary)!
    return CGFloat(CTLineGetTypographicBounds(CTLineCreateWithAttributedString(str), nil, nil, nil))
}

func cor(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
    CGColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}

let fundo   = cor(7, 10, 15)      // --bg do site
let ambar   = cor(255, 176, 32)   // --accent
let claro   = cor(246, 248, 252)  // --text
let apagado = cor(147, 160, 180)  // --text-dim
let verde   = cor(52, 211, 153)

let L = 1200, A = 630

let img = desenha(L, A) { ctx in
    ctx.setFillColor(fundo)
    ctx.fill(CGRect(x: 0, y: 0, width: L, height: A))

    // Brilho âmbar no canto, o mesmo do fundo das telas de login dos apps.
    if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: [cor(255,176,32).copy(alpha: 0.16)!, cor(255,176,32).copy(alpha: 0)!] as CFArray,
                             locations: [0, 1]) {
        ctx.drawRadialGradient(grad, startCenter: CGPoint(x: 980, y: 620), startRadius: 0,
                               endCenter: CGPoint(x: 980, y: 620), endRadius: 620, options: [])
    }

    let marca = CTFontCreateWithName("Helvetica-Bold" as CFString, 108, nil)
    let sub   = CTFontCreateWithName("Helvetica" as CFString, 40, nil)
    let pe    = CTFontCreateWithName("Helvetica-Bold" as CFString, 30, nil)

    // Ponto "ao vivo" — o mesmo sinal verde que aparece no topo dos apps.
    ctx.setFillColor(verde)
    ctx.fillEllipse(in: CGRect(x: 96, y: 402, width: 26, height: 26))

    // "NOT" claro + "TV" âmbar, como a marca dentro dos apps.
    var x: CGFloat = 146
    x += texto(ctx, "NOT", fonte: marca, cor: claro, x: x, y: 380)
    texto(ctx, "TV", fonte: marca, cor: ambar, x: x, y: 380)

    // ⚠️ Era "Filmes, séries e canais ao vivo — numa TV só." — a frase de
    // SERVIÇO DE CONTEÚDO que saiu do site em 11/09 e sobreviveu dentro desta
    // imagem, que é o que aparece quando alguém compartilha o link.
    texto(ctx, "O player para a sua lista IPTV.",
          fonte: sub, cor: apagado, x: 96, y: 296)
    texto(ctx, "Um login para a família toda. Continue de onde parou.",
          fonte: sub, cor: apagado, x: 96, y: 236)

    texto(ctx, "SAMSUNG TV   ·   APPLE TV   ·   IPHONE   ·   IPAD",
          fonte: pe, cor: ambar, x: 96, y: 120)
}

if let img { salva(img, "og.png"); print("og.png gerado (\(L)×\(A))") }
else { print("falhou ao desenhar") }
