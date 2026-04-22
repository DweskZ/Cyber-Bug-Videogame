# OpenClaw Meetup — Game Design / Dev Demo (Dwesk + Lumen)

## Elevator pitch (10–15s)
Mientras la mayoría usa agentes para **chatbots**, nosotros usamos OpenClaw como **compañero de game dev**: diseñar mecánicas, iterar feel, integrar arte (spritesheets) y tocar código/escenas de Godot con trazabilidad (commits). Resultado: un mini platformer tipo HK con boss fight, pickups y pogo.

## Qué es Lumen (mi propósito)
- **Lumen**: asistente “copiloto” para **shippear** un demo jugable.
- En vez de solo “responder”, ayuda en 3 capas:
  1) **Diseño** (loop, lectura, feedback, tuning)
  2) **Producción** (assets, spritesheets, consistencia visual)
  3) **Ingeniería** (Godot scenes/scripts, bugs, colisiones, pipelines)

## Qué hace esto *OpenClaw* (y no un chatbot)
- OpenClaw te da un agente con:
  - **Herramientas** (filesystem MCP, scripts locales, web/refs)
  - **Memoria en proyecto** (notas + continuidad)
  - **Cambios reales en repo** (edita escenas/scripts y hace commits)
  - **Human-in-the-loop**: Dwesk decide dirección, Lumen ejecuta rápido y documenta.

## Historia del desarrollo (resumen)
1) **Inicio (2026-04-11)**
   - Se definió identidad: Lumen.
   - Setup: MCP filesystem + workspace.
   - Se creó el proyecto Godot (`game/meetup`).
   - Prototipo rápido: movimiento, salto, enemigo y ataque.
   - Pivot: vibe tipo Hollow Knight (pogo/down-attack).

2) **Animaciones por spritesheets (2026-04-12+)**
   - Se integraron spritesheets (strips) con `AnimatedSprite2D`.
   - Se creó helper `scripts/spritesheet_anim.gd` para cortar strips y armar `SpriteFrames` en runtime.

3) **Tuning y estabilidad visual (2026-04-13–04-14)**
   - Player: `visual_scale` exportado para iterar tamaño desde Inspector.
   - Boss OpenClaw: integración de sheets; soporte grid + fixes para evitar “drift”/saltos por frames vacíos.
   - Fix clave: “lock” de facing durante ataques para evitar deslizamientos por `flip_h`.

4) **Boss final assets (2026-04-17)**
   - Pipeline de limpieza de sprites (remover fondo con `rembg`).
   - Empaque/strips finales del boss y ajuste de `openclaw_boss.gd` (conteos, offsets, escala).
   - Insight: muchas inconsistencias venían de **frames vacíos** dentro de los sheets.

5) **Pulido para demo (2026-04-22)**
   - Menú minimal de inicio + fondo con arte del boss.
   - Ajustes de tamaños de pickups/pogo/server + hitboxes.
   - Player más grande + ajuste de hitbox y offsets del slash.

## Estructura de speech (5–7 min)
### 0:00–0:30 — Hook
“Hoy no traje un chatbot. Traje un boss fight. OpenClaw no solo sirve para conversar, sirve para construir cosas.”

### 0:30–1:30 — Problema
- Hacer un juego, incluso un demo, tiene fricción: tuning, assets, bugs, iteración.
- En una meetup donde muchos muestran agentes conversacionales, queremos mostrar **agentes como copilotos creativos**.

### 1:30–3:30 — Qué construimos (demo)
- Mini platformer con:
  - movimiento + salto
  - ataque
  - **down-attack pogo**
  - pickups (packets/bugs)
  - arena + boss (OpenClaw)

### 3:30–5:30 — Cómo OpenClaw acelera
- Lumen propone y ejecuta cambios concretos:
  - Ajustes rápidos de escala/hitboxes
  - Integración de spritesheets (strips + runtime slicing)
  - Pipeline de limpieza (rembg) + empaquetado
  - Commits para trazabilidad

### 5:30–6:30 — Lecciones
- Herramientas + repo + memoria > “solo texto”.
- Guardrails: no tocar escenas grandes sin pedirlo (evita accidentes), y commits frecuentes.

### 6:30–7:00 — Cierre
“OpenClaw es una base para agentes que **hacen**. Nosotros lo usamos para game dev, pero el patrón es el mismo para cualquier proyecto: iteración rápida con herramientas y control humano.”

## Checklist de demo en vivo
- Abrir el juego → menú → “Jugar”.
- Mostrar Level01: movimiento, salto, ataque.
- Mostrar pogo con orbes.
- Recoger packets.
- Ir a boss room y mostrar servers + boss.

## 3 frases listas para decir
- “OpenClaw me deja trabajar con un agente que toca el proyecto real, no solo que opina.”
- “La diferencia es el bucle: idea → cambio en Godot → commit → probar.”
- “En game dev, el valor está en iterar rápido y con gusto. Aquí el agente es un teammate.”

## Palabras clave / cosas que puedes nombrar (para que suene a OpenClaw)
### OpenClaw / agentes
- **Agent session** (sesión de agente): un proceso conversacional con contexto y acciones.
- **Tool use**: el agente llama herramientas, no solo “texto”.
- **Skills**: playbooks reutilizables (workflows empaquetados) para tareas repetibles.
- **Sub-agents**: delegar investigación o tareas en paralelo (cuando conviene).
- **Memoria en proyecto**: notas del proyecto para continuidad (decisiones, lecciones, pendientes).
- **Guardrails + trazabilidad**: cambios pequeños, revisables, con commits.

### MCP / herramientas
- **MCP (Model Context Protocol)**: forma estándar de conectar herramientas (filesystem, etc.) al agente.
- **Filesystem MCP**: leer/escribir el repo del juego de forma controlada.

### Godot / game tech (buzzwords que sí mostramos)
- **Scenes/Nodes** (`.tscn`), **GDScript**, composición por nodos.
- **AnimatedSprite2D + SpriteFrames + AtlasTexture** (corte de strips/grids en runtime).
- **Collision layers/masks** (separar mundo vs combate vs pickups).
- **Tuning con @export** (ej: `visual_scale`, `pogo_bounce_multiplier`, etc.).
- **Game feel**: coyote time, jump buffer, hitstop, cámara bump.
