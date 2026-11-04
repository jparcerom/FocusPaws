Bienestar y Foco para Mentes TDAH

Las aplicaciones de productividad del mercado (tipo Notion o Todoist) fallan con las personas con TDAH (Trastorno por Déficit de Atención e Hiperactividad) porque son demasiado aburridas o complejas, lo que les causa frustración.
• El problema del usuario: Falta de dopamina al realizar tareas rutinarias, "ceguera temporal" (no calcular cuánto tardan las cosas) y tendencia a olvidar las tareas si la app requiere demasiados pasos para apuntarlas.
• La App que puedes crear: Un Organizador Gamificado Estricto para TDAH. Una app de tareas con una interfaz ultra-visual y limpia, donde apuntar una tarea tome solo un segundo (o por nota de voz). Para combatir la ceguera temporal, la app incluye temporizadores visuales de cuenta atrás y premia al usuario con mecánicas de juego (puntos, medallas o desbloqueo de avatares) cada vez que completa una tarea.
• Modelo de Monetización (Cómo cobras): Freemium con suscripción. La app permite organizar el día a día gratis. Las funciones avanzadas (como gráficos de humor y energía, widgets visuales interactivos para la pantalla de inicio o sonidos de ruido blanco diseñados para la concentración) se desbloquean por unos 4,99€ al mes.

------------------------------


🧩 Las 3 Funciones Imprescindibles (Tu MVP)

Para no saturar al usuario (lo que provocaría que borre la app), el prototipo inicial debe centrarse en tres herramientas visuales:
• Captura en 1 Toque (Cero fricción): Apuntar una tarea debe requerir un solo botón gigante en la pantalla de inicio o una nota de voz rápida. Si el usuario tiene que elegir categoría, fecha, hora y prioridad antes de guardar, se distraerá y abandonará la app.
• El "Modo Foco" con Cuenta Atrás Visual: Las personas con TDAH sufren de "ceguera temporal" (no perciben el paso del tiempo). En lugar de un reloj digital con números, necesitas un temporizador visual (como un círculo de color que se va vaciando, estilo Time Timer). Esto activa una urgencia visual sana en el cerebro.
• Recompensa de Dopamina Inmediata (Gamificación): Al marcar una tarea como completada, no basta con una simple casilla. Debe haber una animación llamativa, un sonido satisfactorio (pop/estallido) o la suma de puntos para subir de nivel a una mascota virtual. La dopamina instantánea es la clave para que vuelvan a abrir la app.

🎨 Diseño y Experiencia de Usuario (UX/UI)

El TDAH se satura fácilmente ante el desorden visual. Tu diseño debe seguir estas reglas estrictas:
• Colores con propósito: Evita las interfaces llenas de textos pequeños. Usa colores muy contrastados pero relajantes (azules, verdes o pasteles oscuros) para separar las secciones.
• Fuentes tipográficas claras: Utiliza fuentes diseñadas para la legibilidad (como OpenDyslexic o tipografías Sans-Serif muy limpias con buen espaciado).
• Pantalla limpia: Pocos elementos por pantalla. Una sola tarea principal a la vista ayuda a evitar la parálisis por análisis.

🛠️ Hoja de Ruta Tecnológica: ¿Cómo empezar a programar?

Dependiendo de tus conocimientos actuales, tienes dos caminos muy claros para construir la aplicación:

Ruta de Desarrollo	Herramientas Recomendadas	Ventajas para este Proyecto
Sin Código (No-Code)	FlutterFlow o Glide	Ideal si no sabes programar. Permite crear la interfaz visual arrastrando elementos y lanzar el MVP en pocas semanas.
Con Código (Multiplataforma)	Flutter (Dart) o React Native	La mejor opción a largo plazo. Programas el código una sola vez y te permite exportar la app tanto para Android como para iOS, ahorrando meses de trabajo.

------------------------------

1. Propuesta para la Pantalla de Inicio (Mockup Conceptual)

Siguiendo la regla de "cero fricción y baja saturación visual", la pantalla principal de la aplicación no debe parecer una lista de tareas aburrida (como Excel), sino un espacio limpio y vivo.

Estructura de la Pantalla (De arriba a abajo):

1. El Cuartel de la Mascota (Zona Superior - 40% de la pantalla):
	• Aquí vive tu mascota (por ejemplo, un pequeño alienígena, un mapache o un huevo que va evolucionando).
	• Barra de Energía/Felicidad: Una barra visual de color que se llena cuando completas tareas. Si pasas muchas horas sin usar la app, la mascota se duerme o se pone triste (incentivo sutil para regresar).
2. El Botón de Captura Rápida (Zona Central - 20% de la pantalla):
	• Un único botón gigante flotante (+) en el centro o esquina inferior derecha.
	• Al tocarlo, se despliega un cuadro simple: escribes la tarea (o mantienes pulsado para grabarla por voz) y das a Guardar. Sin pedir categorías ni fechas complejas. El cerebro TDAH necesita sacarse la idea de la cabeza ya.
3. La Tarea del Momento (Zona Inferior - 40% de la pantalla):
	• En lugar de una lista infinita de 20 tareas que causa parálisis, la app solo muestra las 3 tareas principales del día en tarjetas grandes y espaciadas.
	• Cada tarjeta tiene un botón de "Iniciar Foco" (Play) que te lleva directamente al temporizador visual.

2. La Lógica de la Mascota (Mecánica de Juego)

Para que el sistema de la mascota funcione y sea sostenible para ti a nivel de desarrollo inicial (MVP), utilizaremos una lógica simple de progresión:
• El Estado Base: Al registrarse, el usuario recibe un "Huevo de Dopamina".
• La Acción Recompensa: Cada vez que el usuario pulsa el botón de completar tarea o termina un bloque de tiempo de enfoque:
	• Suena un efecto de sonido satisfactorio ("¡Pop!" / "¡Chinchín!").
	• La pantalla lanza confeti digital parpadeante.
	• El huevo recibe "puntos de enfoque" hasta que eclosiona en una pequeña criatura.
• Evolución: A las 10 tareas completadas, la criatura crece. A las 50, evoluciona a su forma final. Esto mantiene al usuario motivado a largo plazo.

-------------------

⏱️ Propuesta para la Pantalla de "Modo Foco"

Las personas con TDAH tienen dificultades para medir el paso del tiempo de forma numérica. Ver un reloj con números en cuenta atrás (24:59, 24:58...) les puede generar una ansiedad paralizante o, por el contrario, aburrimiento.
Por eso, la pantalla de FocusPaws se basará en un enfoque 100% visual y gamificado:

Estructura de la Pantalla (De arriba a abajo):

1. La Mascota Concentrada (Zona Superior):
	• La mascota de la app aparece en pantalla haciendo la acción contigo. Si el usuario está estudiando o trabajando, el cachorrito de FocusPaws aparece con unas gafas de lectura, concentrado frente a un libro o un ordenador.
	• Si el usuario sale de la aplicación para mirar redes sociales, la app enviará una notificación sutil simulando la voz de la mascota: "¡Ey! Te espero aquí para seguir trabajando".
2. El Indicador de Tiempo Visual (Zona Central):
	• Sin números grandes. En el centro de la pantalla hay un gráfico circular de color (por ejemplo, una huella de perro o un círculo suave) que se va vaciando o llenando de color gradualmente, como si fuera arena en un reloj.
	• Esto permite que el cerebro procese cuánto tiempo queda de un solo vistazo, de forma intuitiva y sin el estrés del tictac numérico.
3. Controles Sencillos y "Botón de Pánico" (Zona Inferior):
	• Un botón grande de Pausa (por si hay una interrupción real).
	• Un botón de Abandonar (que avisa con un mensaje tierno: ¿Seguro que quieres parar? Tu mascota perderá un poquito de energía).
	• El "Botón de Micro-Pausa" (Novedad de nicho): Un botón especial para cuando el usuario se siente colapsado. Al tocarlo, el temporizador se congela durante 2 minutos y la app le propone una acción física rápida para liberar tensión (ej. "Estira los brazos" o "Bebe un sorbo de agua"), regresando automáticamente al foco al terminar el tiempo.

🏆 El Clímax: La Pantalla de Tarea Completada

Cuando el temporizador visual llega a cero, el usuario entra en la fase de subidón de dopamina sano:
• La pantalla se llena de una animación festiva (confeti digital o huellas parpadeantes).
• La mascota salta de alegría y ladra o celebra con un sonido muy satisfactorio.
• Aparece un mensaje gigante: "¡Conseguido! Has ganado +15 puntos de energía para tu mascota".

------------------------------


🗺️ 1. Diagrama de Flujo de la Aplicación

Este diagrama representa el camino simplificado ("User Flow") que sigue el usuario desde que abre la app hasta que consigue su recompensa. Al ser una app para TDAH, el camino es lineal y libre de distracciones:
text
[ Pantalla de Carga / Inicio ]
            │
            ▼
┌────────────────────────────────────────────────────────┐
│           PANTALLA PRINCIPAL (Home)                    │
│                                                        │
│ 🐾 Mascota (Estado de ánimo/Energía)                   │
│ ➕ Botón Gigante (Añadir Tarea en 1 toque)             │
│ 📋 Tarjetas con las 3 Tareas del Día                   │
└───────────────────┬────────────────────────────────────┘
                    │
                    ├─► [ Toca Botón ➕ ] ──► Abre Ventana Emergente (Escribir/Voz) ──► [ Guardar ] ──► Vuelve a Home
                    │
                    └─► [ Toca Botón Play (▶️) en una Tarea ]
                                 │
                                 ▼
┌────────────────────────────────────────────────────────┐
│           PANTALLA MODO FOCO (Temporizador)            │
│                                                        │
│ 🐶 Mascota Concentrada animada                         │
│ ⏳ Círculo Visual que se vacía (Sin números estresantes)│
│ ⏸️ Pausa / 🚨 Botón Micro-Pausa (2 min de estiramiento)│
└───────────────────────────┬────────────────────────────
                            │
              (El tiempo llega a cero)
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│         PANTALLA DE RECOMPENSA (¡Subidón de Dopamina!) │
│                                                        │
│ 🎉 Animación de Confeti / Sonido "¡Pop!"               │
│ 🐕 Mascota saltando de alegría                         │
│ 💎 +15 Puntos otorgados a la mascota                   │
└───────────────────────────┬────────────────────────────┘
                            │
               (Toca el botón "Continuar")
                            │
                            ▼
               [ Regresa a Pantalla Principal ]
               (La tarea aparece tachada / Mascota feliz)
Use code with caution.

🛠️ 2. Primeras Tareas Técnicas (Sprint 1 - Tu Plan de Trabajo)

Si vas a desarrollar esto tú mismo (ya sea con código como Flutter/React Native o sin código como FlutterFlow), estas son las primeras tareas técnicas prioritarias divididas por bloques lógicos. Concéntrate solo en esto para tener tu primer prototipo listo:

Bloque 1: Configuración del Proyecto y Base de Datos (Backend)

• Tarea 1.1: Crear el proyecto limpio en tu entorno de desarrollo (ej. Flutter) y configurar los colores base de la interfaz (paleta relajante: azul pastel, verde suave y fondo oscuro para evitar fatiga visual).
• Tarea 1.2: Crear la estructura de la base de datos local (SQLite o Hive). Solo necesitas una tabla llamada Tareas con los campos: id (número), titulo (texto) y completada (verdadero/falso).
• Tarea 1.3: Crear una tabla o variable local para la Mascota que guarde los puntos_energia (número entero que empieza en 0).

Bloque 2: Desarrollo de la Interfaz Visual (Frontend)

• Tarea 2.1: Diseñar la Pantalla Principal. Coloca un marcador de posición para la mascota, un botón grande para añadir tareas y un listado dinámico que lea las tareas de la base de datos.
• Tarea 2.2: Programar la lógica del botón Añadir Tarea. Al tocarlo, debe abrir un campo de texto simple. Al darle a guardar, añade el registro a la base de datos y refresca la pantalla al instante.
• Tarea 2.3: Diseñar la Pantalla de Modo Foco. Crea un componente de reloj circular animado (puedes usar librerías como percent_indicator en Flutter) que reciba un tiempo fijo (por ejemplo, 25 minutos) y vaya reduciendo el círculo cromático uniformemente.

Bloque 3: Lógica de Gamificación y Recompensa

• Tarea 3.1: Crear la lógica de Final de Temporizador. Cuando el círculo se vacíe, debe activar un cambio de pantalla automático hacia la pantalla de éxito.
• Tarea 3.2: Implementar la Pantalla de Recompensa. Añade un activador de sonido satisfactorio (un archivo de audio corto tipo .mp3) y suma +15 puntos a la variable de la mascota en la base de datos al pulsar "Continuar".

-------------------------------------
