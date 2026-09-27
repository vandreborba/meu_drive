#!/usr/bin/env python3
"""Gera o ícone do Meu Drive (pasta + selo de sincronizado).

Gera dois PNGs em assets/icone/:
  - icone.png            -> ícone completo (fundo verde arredondado) para uso legado
  - icone_foreground.png -> camada de frente (sem fundo) para o ícone adaptativo

Uso: python3 scripts/gerar_icone.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

SS = 2048  # supersampling para bordas suaves
VERDE = (46, 125, 50, 255)
VERDE_ESCURO = (20, 72, 28, 255)
BRANCO = (255, 255, 255, 255)


def desenhar_conteudo(d: ImageDraw.ImageDraw, k: float) -> None:
    """Desenha a pasta branca com o selo de check."""

    def x(v: float) -> float:
        return v * k

    # Aba da pasta.
    d.rounded_rectangle([x(300), x(330), x(505), x(445)], radius=x(30), fill=BRANCO)
    # Corpo da pasta.
    d.rounded_rectangle([x(280), x(400), x(744), x(700)], radius=x(46), fill=BRANCO)
    # Selo (círculo verde-escuro com check branco).
    cx, cy, r = x(716), x(690), x(152)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=VERDE_ESCURO, outline=BRANCO, width=int(x(28)))
    d.line(
        [(cx - x(64), cy + x(6)), (cx - x(16), cy + x(56)), (cx + x(72), cy - x(58))],
        fill=BRANCO,
        width=int(x(32)),
        joint="curve",
    )


def main() -> None:
    destino = Path(__file__).resolve().parent.parent / "assets" / "icone"
    destino.mkdir(parents=True, exist_ok=True)

    # Camada de conteúdo (transparente), desenhada em alta resolução.
    conteudo = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    desenhar_conteudo(ImageDraw.Draw(conteudo), SS / 1024)
    conteudo = conteudo.crop(conteudo.getbbox())

    # Camada de frente do ícone adaptativo (sem fundo), centralizada.
    frente = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    alvo_frente = conteudo.resize((int(1024 * 0.62), int(conteudo.height / conteudo.width * 1024 * 0.62)), Image.LANCZOS)
    frente.alpha_composite(alvo_frente, ((1024 - alvo_frente.width) // 2, (1024 - alvo_frente.height) // 2))
    frente.save(destino / "icone_foreground.png")

    # Ícone completo com fundo verde arredondado e leve gradiente.
    fundo = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    desenho_fundo = ImageDraw.Draw(fundo)
    for y in range(SS):
        t = y / SS
        desenho_fundo.line(
            [(0, y), (SS, y)],
            fill=(
                int(46 * (1 - t) + 20 * t),
                int(125 * (1 - t) + 72 * t),
                int(50 * (1 - t) + 28 * t),
                255,
            ),
        )
    mascara = Image.new("L", (SS, SS), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, SS - 1, SS - 1], radius=int(SS * 0.22), fill=255)
    fundo.putalpha(mascara)
    fundo = fundo.resize((1024, 1024), Image.LANCZOS)

    completo = fundo.copy()
    alvo = conteudo.resize((int(1024 * 0.58), int(conteudo.height / conteudo.width * 1024 * 0.58)), Image.LANCZOS)
    completo.alpha_composite(alvo, ((1024 - alvo.width) // 2, (1024 - alvo.height) // 2))
    completo.save(destino / "icone.png")

    print("Gerados:", destino / "icone.png", "e", destino / "icone_foreground.png")


if __name__ == "__main__":
    main()
