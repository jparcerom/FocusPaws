Bienestar y Foco para Mentes TDAH

Las aplicaciones de productividad del mercado (tipo Notion o Todoist) fallan con las personas con TDAH (Trastorno por Déficit de Atención e Hiperactividad) porque son demasiado aburridas o complejas, lo que les causa frustración.
• El problema del usuario: Falta de dopamina al realizar tareas rutinarias, "ceguera temporal" (no calcular cuánto tardan las cosas) y tendencia a olvidar las tareas si la app requiere demasiados pasos para apuntarlas.
• La App que puedes crear: Un Organizador Gamificado Estricto para TDAH. Una app de tareas con una interfaz ultra-visual y limpia, donde apuntar una tarea tome solo un segundo (o por nota de voz). Para combatir la ceguera temporal, la app incluye temporizadores visuales de cuenta atrás y premia al usuario con mecánicas de juego (puntos, medallas o desbloqueo de avatares) cada vez que completa una tarea.
• Modelo de Monetización (Cómo cobras): Freemium con suscripción. La app permite organizar el día a día gratis. Las funciones avanzadas (como gráficos de humor y energía, widgets visuales interactivos para la pantalla de inicio o sonidos de ruido blanco diseñados para la concentración) se desbloquean por unos 4,99€ al mes.

------------------------------


🧩 Las 3 Funciones Imprescindibles (Tu MVP)

Para no saturar al usuario (lo que provocaría que borre la app), el prototipo inicial debe centrarse en tres herramientas visuales:
• Captura en 1 Toque (Cero fricción): Apuntar una tarea debe requerir un solo botón gigante en la pantalla de inicio, por escritura o mediante dictado de voz. La transcripción debe poder revisarse y editarse antes de guardar. El micrófono solo se activa cuando el usuario elige dictar; el reconocimiento usa el servicio de voz del dispositivo y FocusPaws no guarda audio.
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
• Progresión por niveles: Cada tarea otorga puntos según su tamaño: 10, 20 o 40. Los niveles 1 y 2 requieren 150 puntos cada uno; los niveles 3 a 5, 180 cada uno; y los niveles 6 a 8, 210 cada uno. El requisito aumenta 30 puntos cada tres niveles. La insignia del animal elegido muestra el nivel actual, celebra cada subida y la barra muestra el avance y objetivo del siguiente nivel. Los puntos acumulados se conservan para calcular niveles, pero el total de por vida no se muestra para mantener la pantalla sencilla.
• Personalización inicial: En el primer inicio, la persona elige su nombre y uno de seis animales, organizados en dos filas de tres. El saludo de la pantalla principal muestra solo su nombre; el animal seleccionado aparece en el recuadro de progreso y es quien celebra las subidas de nivel. Los animales se llaman Nori (perro), Kitty (gato), Foxy (zorro), Bunny (conejo), Bruno (oso) y Panda.

### Ajustes acordados a la pantalla de tareas

- La cabecera muestra «FocusPaws» y el botón «Finalizar día» alineado a su derecha; el acceso al perfil se mantiene en el selector y su panel, no en la pantalla de tareas.
- La tarjeta de progreso omite el encabezado «Tu compañero de hoy» y la línea de puntos totales. Conserva el nombre y nivel de la mascota, el progreso al siguiente nivel y las recompensas disponibles.
- La sección de tareas se titula «Tu reto del día», el contador usa el formato «0/0 tareas hechas» y al completar todo se muestra «¡Misión cumplida por hoy!».

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
• Aparece un mensaje gigante con la recompensa del tamaño elegido: "¡Conseguido! Has ganado +10, +20 o +40 puntos de energía para tu mascota".

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
│ 💎 Puntos según el tamaño de la tarea (10/20/40)        │
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
• Tarea 2.2: Programar la lógica del botón Añadir Tarea. Al tocarlo, debe abrir un campo de texto simple con la opción de dictar en español. La transcripción se puede revisar y editar antes de guardar. Ofrece tres tamaños rápidos: Paso corto (15 min), Bloque estándar (30 min) y Gran esfuerzo (45 min). Al guardar, añade el título y el tiempo estimado a la base de datos y refresca la pantalla al instante.
• Tarea 2.3: Diseñar la Pantalla de Modo Foco. Crea un componente de reloj circular animado (puedes usar librerías como percent_indicator en Flutter) que tome la estimación de la tarea (15, 30 o 45 minutos) y vaya reduciendo el círculo cromático uniformemente.

Bloque 3: Lógica de Gamificación y Recompensa

• Tarea 3.1: Crear la lógica de Final de Temporizador. Cuando el círculo se vacíe, permite añadir una prórroga visual de 5 minutos, pasar al modo libre ascendente o finalizar la tarea.
• Tarea 3.2: Implementar la Pantalla de Recompensa. Añade un activador de sonido satisfactorio (un archivo de audio corto tipo .mp3) y concede los puntos asociados al tamaño de la tarea (10, 20 o 40) al pulsar "Continuar".

-------------------------------------

## Funcionamiento modo foco desarrollado

En FocusPaws, el Modo Foco debe ser flexible y adaptarse a lo que llamamos "ventanas de productividad variable".
Aquí tienes la lógica exacta de cómo debe reaccionar la aplicación en ambos escenarios:

Escenario 1: El usuario finaliza la tarea ANTES de que se acabe el tiempo ⏱️🏃‍♂️

Imagina que la tarea es un Bloque estándar de 30 minutos y el usuario la termina después de 15 minutos de foco.
• El error común en otras apps: Obligar al usuario a esperar a que el reloj llegue a cero o no darle los puntos completos por "cancelar" el temporizador. Esto genera frustración.
• Cómo debe funcionar en FocusPaws: Habilitamos un botón visible que dice "¡Terminé antes!".
• La lógica de la recompensa:
	• ¡Premio por eficiencia! Se otorgan a la mascota los puntos completos del tamaño elegido: +10, +20 o +40.
	• La app lo celebra con un mensaje de refuerzo positivo adaptado: "¡Guau! Tu cerebro ha volado hoy. [Nombre de la mascota] está orgulloso de tu velocidad".
	• El tiempo restante del temporizador se convierte automáticamente en "Tiempo de Bonificación para Descanso" (se suma a su próximo descanso para que pueda relajarse sin culpa).

Escenario 2: El usuario finaliza la tarea DESPUÉS (El tiempo llega a cero y no ha terminado) ⏳🔄

El temporizador elegido para la tarea llega a cero, pero el usuario todavía está a mitad de la tarea.
• El error común en otras apps: Cortar la concentración del usuario con una alarma estridente y obligarle a registrar la tarea como "fallida" o iniciar un descanso obligatorio, rompiendo su estado de flujo.
• Cómo debe funcionar en FocusPaws (El "Modo Horas Extras"): Cuando el tiempo llega a cero, el círculo visual desaparece y la app entra en un estado "Zen" secundario. La mascota cambia su animación a una posición de ánimo (como pompones o aplausos silenciosos) y aparece un menú con dos opciones sencillas:
	1. "Necesito 5 minutos más": Añade un pequeño minitemporizador visual extra de inmediato sin salir de la pantalla.
	2. "Seguir en modo libre": El reloj empieza a contar hacia adelante (en positivo) registrando cuánto tiempo extra necesita, de forma muy discreta.
• La lógica de la recompensa:
	• Cuando el usuario por fin pulsa "Finalizar tarea", recibe los puntos base de su tarea (+10, +20 o +40) por haber sido perseverante y no abandonar.
	• Extra por esfuerzo: Si completó más de 10 minutos extra, la mascota recibe un "snack" o un objeto cosmético coleccionable como recompensa por su resistencia.

🎨 Resumen visual para el flujo de programación

Para tu código o estructura en FlutterFlow, la lógica de la pantalla del Temporizador se divide en estas tres salidas:

Acción del Usuario	Estado del Reloj	Destino	Recompensa en FocusPaws
Toca "¡Terminé antes!"	Detenido manualmente	Pantalla Recompensa	Puntos del tamaño + posible tiempo restante transferido al descanso.
Tiempo Agotado (Y ya terminó)	Llega a 00:00	Pantalla Recompensa	Puntos del tamaño.
Tiempo Agotado (Y NO ha terminado)	Llega a 00:00	Prórroga / Modo Libre	Puntos del tamaño al acabar + bonificación por persistencia.

-------------------------------------

## Tiempo definido por tarea

1. Estimación en un Toque (Sin escribir números)

Cuando el usuario crea una tarea, no le obligues a escribir la hora exacta (eso causa fricción). En su lugar, ofrécele 3 botones rápidos de "Tamaño de Tarea":
• Paso Corto (15 min): Para cosas rápidas (ej. Hacer la cama, mandar un correo).
• Bloque Estándar (30 min): Para tareas normales (ej. Estudiar un tema, limpiar la habitación).
• Gran Esfuerzo (45 min): Para tareas complejas que requieren mucho foco.
(Nota de diseño para TDAH: No pongas opciones de más de 45 o 60 minutos. Es mejor educar al usuario a dividir las tareas grandes en subtareas pequeñas para evitar que se rinda antes de empezar).

2. La Regla del "Límite Antitrampas" (Lógica del código)

Para evitar el abuso del botón "¡Terminé antes!", añadiremos una regla matemática muy sencilla en el código de tu aplicación:
• La Regla del 50%: Si el usuario pulsa "¡Terminé antes!" habiendo cumplido menos de la mitad del tiempo estimado, la aplicación sospechará que es un "falso positivo" (o que calculó muy mal).
• Cómo reacciona la app: No le da la bonificación completa de tiempo para el descanso. En su lugar, la mascota le dice de forma amigable: "¡Vaya, qué rápido! Vamos a guardar estos minutos extra en tu hucha, pero tu descanso será el estándar para no perder el ritmo".

📊 Tabla de Recompensas Equilibrada

Definiendo el tiempo estimado de la tarea, tu base de datos y la lógica de recompensas quedarían perfectamente equilibradas así:

Tamaño de Tarea	Tiempo Estimado	Puntos Base para la Mascota	Bonificación Máxima de Descanso
Paso Corto	15 minutos	+10 pts	Máximo 3 minutos extra
Bloque Estándar	30 minutos	+20 pts	Máximo 7 minutos extra
Gran Esfuerzo	45 minutos	+40 pts	Máximo 10 minutos extra


🛠️ Impacto en tus Tareas Técnicas

Esto solo añade una pequeña tarea a tu plan de trabajo: en la Tarea 2.2 (Ventana emergente de añadir tarea), además del campo de texto, pondremos estos 3 botones de tiempo predefinido (15, 30, 45 min). Al guardar la tarea, se guardará también ese límite en la base de datos.
Con esta solución el sistema queda blindado contra las trampas del cerebro

### Decisiones acordadas para esta implementación

- La tabla de recompensas por tamaño sustituye a la recompensa fija anterior y se aplica tanto al completar desde Inicio como al terminar una sesión de foco, incluso después de una prórroga o en modo libre.
- Si se pulsa «¡Terminé antes!» antes de consumir la mitad del tiempo estimado, no se suman los minutos restantes al saldo de descanso. Se mantiene el descanso estándar y se muestra un mensaje amable.
- Si se ha completado al menos la mitad, el tiempo restante se suma al saldo de descanso hasta el máximo indicado para el tamaño. El excedente no se acumula en otra hucha.
- Las tareas guardadas antes de definir tamaños se consideran Bloque estándar (30 minutos y 20 puntos al completarse con la nueva tabla). Los puntos ya obtenidos antes del cambio se conservan sin ajustes retroactivos.

-------------------------------------

## Gestión de perfiles

### Decisiones acordadas para esta implementación

- Al abrir la aplicación con perfiles guardados se muestra un selector. Cada botón de perfil muestra el nombre y el animal escogido.
- Al seleccionar un perfil se abre un panel intermedio con botones grandes para cambiar el animal, editar el nombre, abrir la habitación/álbum y acceder a las tareas.
- «Finalizar día» vuelve al selector sin borrar tareas, puntos, recompensas ni el historial diario.
- Los datos de progreso se guardan por identificador de perfil. Al actualizar desde la versión de un solo perfil, el perfil existente conserva el registro anterior; los perfiles nuevos empiezan con progreso independiente.
- La creación de usuarios adicionales queda preparada para la versión de pago: está visible en desarrollo y oculta de forma predeterminada en compilaciones release. La compilación de desarrollo puede habilitarla con `--dart-define=FOCUSPAWS_PREMIUM_MULTIUSER=true`; en la versión gratuita solo aparece el perfil predeterminado y los demás datos no se eliminan. Esta bandera todavía no sustituye la integración de compra.

------------------------------------

## Sistema de persistencia

1. El Sistema de Persistencia: El "Álbum de Logros"

El cerebro con TDAH sufre a menudo de falta de memoria prospectiva y sensación de "no estar avanzando". Guardar el historial de forma persistente (usando bases de datos locales como Room o DataStore en Android de forma nativa, o Hive/Isar si usas Flutter) es clave para el tratamiento psicológico.

Vamos a guardar estos datos para que se recuperen en cada sesión y no se pierdan con el día a día.
Aquí vamos a prepararlo de tal manera que en la versión gratuita no se muestre la habitación que hablamos a continuación pero si que guarde el progreso en la pantalla principal.

Vamos a dejarlo preparado para que cuando esté la aplicación desarrollada completamente se puedan bloquear los aspectos definidos para la versión de pago. Las iremos definiendo a medida que avance el desarrollo, mientras estamos en desarrollo necesitamos verlo todo.

• Cómo implementarlo visualmente: No crees gráficos estadísticos aburridos (estilo Excel de empresa). Crea la "Habitación de la Mascota" o un "Álbum de Pegatinas".
• La lógica: Cada día que el usuario complete sus 3 tareas persistidas, el sistema desbloquea una pegatina, una prenda para vestir a su mascota o un mueble para su habitación virtual.
• El beneficio: Al ver el historial de forma gráfica, el usuario ve el impacto de su esfuerzo acumulado de un vistazo.

### Decisiones acordadas para esta implementación

- Se implementa un Álbum de Pegatinas. Cada pegatina representa un día local en el que se completaron tres tareas distintas; las finalizaciones desde Inicio y desde el Modo Foco cuentan.
- El avance del día se reinicia al cambiar la fecha local. Volver a marcar la misma tarea como completada no suma más de una vez en ese día.
- Las tareas, puntos, tamaños, saldo de descanso, snacks, finalizaciones diarias y fechas de pegatinas desbloqueadas se guardan juntos en el registro local. Los datos antiguos siguen siendo compatibles; no se atribuyen a fechas pasadas las tareas que no tenían historial diario.
- El álbum se muestra durante el desarrollo. La bandera `FocusPawsFeatures.showStickerAlbum` permite ocultarlo posteriormente; el progreso diario permanece visible en Inicio.

------------------------------------

🛠️ Entorno de desarrollo y forma de trabajo

• Android Studio está instalado en `F:\Android\Android Studio`; el Android SDK y el emulador están en `F:\Android\Sdk`. Usa estas rutas al configurar o ejecutar las herramientas de Android; no busques primero en las rutas predeterminadas.
• El SDK de Flutter se instalará en `F:\Android\flutter`.
• El emulador Pixel 6 tiene Gboard configurado inicialmente en inglés (EE. UU.). Para escribir con tildes, añade español en Ajustes → Sistema → Teclado → Teclado en pantalla → Gboard → Idiomas; la aplicación no filtra las letras acentuadas.
• Desarrollaremos la aplicación de forma incremental: completaremos y verificaremos cada funcionalidad antes de pasar a la siguiente.
• La interfaz debe ser cuidada, clara e intuitiva, con especial atención a reducir la carga cognitiva y la saturación visual para las personas con TDAH.
