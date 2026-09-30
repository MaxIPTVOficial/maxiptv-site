import Foundation
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers

// Gera o ícone do site (favicon) na marca do Max IPTV.
//
// ⚠️ Existe porque o site não tinha ícone NENHUM — nem arquivo, nem referência
// no HTML — e por isso o Google mostrava um globo genérico ao lado do resultado
// (achado do Edu em 02/09, na primeira vez que o site apareceu na busca).
//
// O que o Google pede: quadrado, múltiplo de 48px, no mesmo domínio e
// alcançável. Geramos 48/96/192/512 — os pequenos para a aba do navegador, os
// grandes para atalho de celular e para o Google escolher.
//
// A marca aqui é o "TV" âmbar sobre o fundo escuro (até 30/09 era o "M" do
// MAX IPTV). O logotipo inteiro ("NOTTV") não cabe: a 48px viraria um borrão. Ícone precisa funcionar no
// tamanho MENOR em que vai aparecer.
//
// Uso:  swift tools/GerarIcone.swift

func desenha(_ lado: Int, _ corpo: (CGContext) -> Void) -> CGImage? {
    guard let ctx = CGContext(data: nil, width: lado, height: lado, bitsPerComponent: 8,
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

func cor(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
    CGColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}

let fundo = cor(7, 10, 15)      // --bg do site
let ambar = cor(255, 176, 32)   // --accent
let verde = cor(52, 211, 153)

for lado in [48, 96, 192, 512] {
    // ⚠️ A closure vai como ARGUMENTO, não como trailing closure: o Swift não
    // aceita trailing closure dentro da condição de um `guard`.
    let imagem = desenha(lado, { ctx in
        let L = CGFloat(lado)
        // Cantos arredondados: o Google e os navegadores recortam sozinhos, mas
        // um quadrado seco fica duro quando não recortam.
        let raio = L * 0.22
        let caminho = CGPath(roundedRect: CGRect(x: 0, y: 0, width: L, height: L),
                             cornerWidth: raio, cornerHeight: raio, transform: nil)
        ctx.addPath(caminho); ctx.clip()
        ctx.setFillColor(fundo)
        ctx.fill(CGRect(x: 0, y: 0, width: L, height: L))

        // O "TV" ocupando quase todo o quadro — num favicon de 48px, margem é
        // espaço desperdiçado.
        let fonte = CTFontCreateWithName("Helvetica-Bold" as CFString, L * 0.56, nil)
        let attrs: [CFString: Any] = [kCTFontAttributeName: fonte, kCTForegroundColorAttributeName: ambar]
        let str = CFAttributedStringCreate(nil, "TV" as CFString, attrs as CFDictionary)!
        let linha = CTLineCreateWithAttributedString(str)
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let largura = CGFloat(CTLineGetTypographicBounds(linha, &ascent, &descent, nil))
        // Um pouco abaixo do centro: com "TV" (mais largo que o "M"), o topo do T
        // encostava na bolinha verde do canto. Medido na primeira geração.
        ctx.textPosition = CGPoint(x: (L - largura) / 2, y: (L - (ascent - descent)) / 2 - L * 0.08)
        CTLineDraw(linha, ctx)

        // O ponto "ao vivo" — o mesmo sinal verde da marca, no canto.
        let d = L * 0.13
        ctx.setFillColor(verde)
        ctx.fillEllipse(in: CGRect(x: L * 0.09, y: L * 0.77, width: d, height: d))
    })
    guard let imagem else { continue }
    salva(imagem, "icone-\(lado).png")
    print("icone-\(lado).png")
}
