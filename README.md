# Echoes in the Fog - Roblox

Proyecto de horror/survival cooperativo en Roblox, inspirado en la tensión ambiental de Silent Hill y juegos de extracción por objetivos.

## Estado actual

- Control de jugador en tercera persona con cámara personalizada.
- Sistema de stamina, sprint y penalización por heridas críticas.
- Inventario con pickup de objetos, notas y consumibles.
- Sistema de armas de fuego y melee con equipamiento, disparo hitscan y recarga.
- Interacciones por ProximityPrompt (puertas, botiquines, notas, revive, objetos).
- IA de peligro con persecución y daño por contacto.
- Checkpoints de respawn y estados de jugador (Sano/Abatido).
- Lobby multijugador con countdown por sala (hasta 4 jugadores) y teletransporte.

## Arquitectura (resumen)

- Cliente: controladores en src/client/CoreModules (input, cámara, movimiento, UI, linterna, radio).
- Servidor: managers en src/server/ModuleScripts (inventario, estados, armas, equipamiento, remotes).
- Shared: constantes y catálogos en src/shared/ModuleScripts.
- Interacciones: acciones desacopladas en src/server/Interactions/Actions.

## Documentacion tecnica

- [Analisis tecnico - Iteracion 1](docs/analisis-iteracion-1.md)

## Seguridad aplicada

- Validación server-side de estado para endpoints de arma.
- Debounce server-side para recarga de arma.
- Lock atómico por puerta para evitar race conditions al consumir llaves.
- Protección cliente ante fallos de InvokeServer usando pcall.
- Sanity check server-side de desplazamiento para mitigar speed exploit básico.

## Ejecución local

- Requiere Rojo para sincronizar el proyecto con Roblox Studio.
- Abrir el proyecto y correr en modo Play o Local Server para validar interacciones multijugador.

## Estructura

- src/client
- src/server
- src/shared
- src/workspace
