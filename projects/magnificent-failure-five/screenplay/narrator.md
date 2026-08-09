# Narrator VO

Voice: classic deep American movie-trailer narrator. Delivery: absolute sincerity — the comedy is in the picture, never in the read. Generate one file per line (ElevenLabs free tier is sufficient; ~0.8–1.5 s each). Settings that work: stability ~35–40%, similarity ~75%, slight style exaggeration.

| file | line | plays over |
|---|---|---|
| n01.wav | "In a world…" | sh01 |
| n02.wav | "…that cried out for heroes…" | sh02 |
| n03.wav | "…destiny answered." | sh03 |
| n04.wav | "Five men. One mission." | sh04 |
| n05.wav | "No fear." | sh05 |
| n06.wav | "No limits." | sh06 |
| n07.wav | "Coming soon. Unfortunately." | sh07 (title) |

Save to `assets/audio/narrator/`. Each line starts ~0.3 s after its shot begins (assemble.sh handles timing automatically).

# Music

One continuous 30 s epic trailer cue → `assets/audio/music.mp3`. Suno/Udio if available, else local ACE-Step (free). Prompt:

> Epic cinematic trailer orchestra, 30 seconds, slow build with braams and taiko hits, heroic brass theme that keeps almost resolving, big final stinger around 26 seconds, no vocals.
