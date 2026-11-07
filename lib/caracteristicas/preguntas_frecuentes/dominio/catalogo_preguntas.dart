import 'dart:math';

import 'package:oncuidar/caracteristicas/biblioteca/dominio/material_educativo.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';

const mensajeBienvenidaChat =
    'Hola, soy tu asistente de orientación. Elige una pregunta sugerida o '
    'escríbeme tu duda sobre el cuidado de tu niño.';

const mensajeSinCoincidencia =
    'Aún no tengo una respuesta exacta. Puedes preguntarme sobre fiebre, '
    'sangrado, catéter, alimentación, molestias digestivas, piel, dolor, '
    'vacunas o cuidados en casa. Ante cualquier duda, consulta con el equipo '
    'médico de tu niño.';

const List<PreguntaBase> preguntasFrecuentes = [
  PreguntaBase(
    id: 'fiebre',
    categoria: 'Fiebre y urgencias',
    pregunta: '¿En qué momento una fiebre se convierte en una emergencia?',
    respuesta:
        'Siempre la fiebre es urgente. Cualquier temperatura igual o mayor a 38 °C (rectal o axilar) es una emergencia médica inmediata en un niño en tratamiento por cáncer.',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    claves: [
      'fiebre',
      'temperatura',
      'termómetro',
      '38',
      'grados',
      'emergencia',
      'calentura',
      'afiebrado',
    ],
  ),
  PreguntaBase(
    id: 'cuando-urgencia',
    categoria: 'Fiebre y urgencias',
    pregunta: '¿Cuándo acudir al servicio de urgencia?',
    respuesta:
        'Hay que acudir a urgencia cuando el niño tenga fiebre, sangrado nasal, petequias, cuando vomite o cuando no quiera comer absolutamente nada.',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    claves: [
      'urgencia',
      'urgencias',
      'hospital',
      'acudir',
      'llevar',
      'emergencia',
      'servicio',
    ],
  ),
  PreguntaBase(
    id: 'efectos-quimio-preocupantes',
    categoria: 'Fiebre y urgencias',
    pregunta:
        '¿Cuándo me debo preocupar por los efectos secundarios de la quimioterapia?',
    respuesta:
        'La fiebre es una de las urgencias oncológicas más frecuentes y potencialmente graves en un niño en tratamiento por cáncer. Las temperaturas extremas, muy bajas o muy altas, pueden indicar una infección grave. Consulta si hay:\n• 38 °C que no baja luego de una hora, sin uso de medicamentos ni medidas físicas (paños tibios).\n• Temperatura mayor a 38,5 °C en una toma.\n• Temperatura menor a 35,5 °C mantenida, que no cede con abrigo, en niños menores de 2 años.\n• Calofríos, aunque la temperatura no llegue a 38 °C: se considera fiebre de consulta.\nTambién si aparece:\n• Sangrado o moretones sin motivo.\n• Sarpullido (erupción en la piel).\n• Reacción alérgica, como hinchazón de la boca o la garganta, picazón intensa o dificultad para tragar.\n• Escalofríos intensos.\n• Dolor o sensibilidad donde se inyectó la quimioterapia o donde está el catéter.\n• Dolor no habitual, incluidos dolores de cabeza intensos.\n• Falta de aire o dificultad para respirar: llama primero al 131 (SAMU).\n• Diarrea o vómitos persistentes.\n• Sangre en las heces o en la orina.',
    fuente:
        'PINDA, Urgencias (pindachile.cl/urgencias) y American Cancer Society, efectos secundarios de la quimioterapia',
    contenidoRelacionadoId: 'efectos-secundarios-de-la-quimioterapia-infantil',
    claves: [
      'preocupar',
      'efectos',
      'secundarios',
      'quimioterapia',
      'quimio',
      'calofríos',
      'escalofríos',
      'alergia',
      'sarpullido',
      'hipotermia',
      'frío',
    ],
  ),
  PreguntaBase(
    id: 'complicaciones',
    categoria: 'Fiebre y urgencias',
    pregunta: '¿Qué complicaciones puede tener el tratamiento oncológico?',
    respuesta:
        'Efectos inmediatos:\n• Infecciones graves (neutropenia febril).\n• Náuseas y vómitos.\n• Anemia.\n• Toxicidad en los órganos por la quimioterapia.\nA largo plazo:\n• Problemas cognitivos.\n• Disfunción de la tiroides.\n• Infertilidad.\n• Segundos cánceres.\n• Pérdida auditiva.\n• Trastornos del crecimiento.',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    contenidoRelacionadoId: 'efectos-del-tratamiento-oncologico-infantil',
    claves: [
      'complicaciones',
      'neutropenia',
      'anemia',
      'toxicidad',
      'largo plazo',
      'tiroides',
    ],
  ),
  PreguntaBase(
    id: 'petequias',
    categoria: 'Sangrado',
    pregunta:
        'Si le sangra la nariz o aparecen petequias, ¿qué debo hacer antes de llegar al hospital?',
    respuesta:
        'Si en la piel aparecen pequeños puntos rojos (petequias), moretones sin motivo, o sangra la nariz o las encías, contacta al equipo tratante y cuéntale la situación para recibir orientación. Es probable que algunos componentes de la sangre estén bajos (glóbulos rojos, plaquetas) y sea necesario controlar con exámenes y transfundir.\nSi con los días aparecen más petequias, o el sangrado no cede al presionar la zona, el niño debe ser evaluado y atendido en el hospital.',
    fuente: 'PINDA, Urgencias (pindachile.cl/urgencias)',
    claves: [
      'sangra',
      'sangrado',
      'sangre',
      'petequias',
      'puntos rojos',
      'moretones',
      'encías',
      'hematoma',
    ],
  ),
  PreguntaBase(
    id: 'taponamiento-nasal',
    categoria: 'Sangrado',
    pregunta: '¿Cómo hacer un taponamiento nasal si le sangra la nariz?',
    respuesta:
        '1. Mantente tranquilo y calma al niño.\n2. Siéntalo y pídele que mire hacia abajo. Si levanta la cabeza y el sangrado es abundante, puede tragar sangre y atorarse.\n3. Presiona con los dedos la parte blanda de la nariz (aleta nasal), introduce un algodón en la fosa nasal y mantén la cabeza hacia abajo por 10 minutos.\n4. Si tienes una compresa fría, aplícala en la zona para ayudar a detener el sangrado. Es recomendable guardar una en el congelador para estas urgencias.\n5. Observa si el algodón sigue manchándose y la sangre escurre por los bordes, y pregúntale si siente que traga sangre: en ese caso el sangrado sigue activo. No retires el algodón, porque se saldría el tapón de coagulación y el sangrado continuaría. Es preferible apoyar otro algodón por fuera para absorber el exceso.\n6. Si a pesar de estas medidas el sangrado continúa, acude al servicio de urgencia.',
    fuente: 'PINDA, Urgencias (pindachile.cl/urgencias)',
    claves: [
      'nariz',
      'nasal',
      'taponamiento',
      'epistaxis',
      'algodón',
      'sangra la nariz',
      'tapón',
    ],
  ),
  PreguntaBase(
    id: 'cateter-cuidados',
    categoria: 'Catéter',
    pregunta: '¿Qué cuidados se deben tener con el catéter central?',
    respuesta:
        'Muchas quimioterapias irritan las venas y, con el tiempo, se vuelve más difícil puncionarlas e instalar vías venosas. Por eso hay que cuidar bien el catéter. Los cuidados dependen del tipo.\nCatéter parcialmente implantable (Hickman o Groshong), con una parte dentro del cuerpo y otra afuera:\n1. Evitar que se salga.\n2. Mantener un buen aseo, con baños y duchas.\n3. No sumergir el catéter: el apósito no debe mojarse. Envuélvelo con plástico y lava esa zona por partes con un paño húmedo y suave.\n4. No bañarse en piscinas, lagos, ríos ni mar.\n5. Si el catéter se moja o humedece, comunícate de inmediato con enfermería de tu centro de salud, porque hay que hacer curación y cambiar el apósito.\n6. Evitar juegos bruscos o deportes de contacto, para que no se salga por accidente.\nCatéter totalmente implantable (Gripper), bajo la piel, que se ve como un pequeño bulto:\n1. Mantener aseo, baño y ducha.\n2. Si no tiene la aguja instalada, puede ducharse sin problema.\n3. Si tiene la aguja instalada, el apósito no debe mojarse: envuélvelo con plástico, evita que el chorro de agua llegue a la zona y lava por partes con un paño húmedo y suave.\n4. No bañarse en piscinas, lagos, ríos ni mar, aunque el catéter esté bajo la piel.\n5. Si el parche se moja o humedece, comunícate de inmediato con enfermería, porque hay que hacer curación y cambiar el apósito.\n6. Evitar juegos bruscos o deportes de contacto.\n7. Evitar golpes en la zona del reservorio.',
    fuente: 'PINDA, Urgencias (pindachile.cl/urgencias)',
    contenidoRelacionadoId: 'guia-del-cateter-venoso-central-pediatrico',
    claves: [
      'catéter',
      'cateter',
      'hickman',
      'groshong',
      'gripper',
      'reservorio',
      'apósito',
      'parche',
      'curación',
      'aguja',
      'ducha',
      'moja',
    ],
  ),
  PreguntaBase(
    id: 'cateter-bano',
    categoria: 'Catéter',
    pregunta:
        '¿Se puede bañar en ríos, lagos o piscinas con el catéter puesto?',
    respuesta:
        'No es recomendable, sin importar el tipo de catéter, para prevenir infecciones y evitar que se salga o se desplace.',
    fuente: 'PINDA, Urgencias (pindachile.cl/urgencias)',
    claves: ['piscina', 'lago', 'río', 'mar', 'bañar', 'nadar', 'playa'],
  ),
  PreguntaBase(
    id: 'cateter-sale',
    categoria: 'Catéter',
    pregunta: '¿Qué hago si se le sale el catéter o se golpea la zona?',
    respuesta:
        'Si notas que el niño se tiró el catéter, avisa siempre a su equipo de salud para que lo evalúen. Si notas que la manguera (lumen) que queda afuera está más larga de lo que recuerdas, también avisa, porque puede haberse desplazado.',
    fuente: 'PINDA, Urgencias (pindachile.cl/urgencias)',
    contenidoRelacionadoId: 'como-proteger-el-cateter-venoso-de-tu-hijo',
    claves: [
      'sale',
      'salió',
      'tiró',
      'golpe',
      'golpea',
      'desplazado',
      'manguera',
      'lumen',
      'largo',
    ],
  ),
  PreguntaBase(
    id: 'alimentacion-efectos',
    categoria: 'Alimentación',
    pregunta: '¿Cómo afecta la alimentación a los niños con cáncer?',
    respuesta:
        'La enfermedad y su tratamiento pueden causar desnutrición, lo que afecta directamente las defensas, aumenta el riesgo de infecciones, disminuye la tolerancia a la quimioterapia y altera el crecimiento y desarrollo.\nSus consecuencias son pérdida de masa muscular, menos defensas y más infecciones en el sitio de la cirugía, más estrés, menor calidad de vida, mayor toxicidad de los tratamientos (que obliga a reducirlos o interrumpirlos) y mayor riesgo de mortalidad.',
    fuente:
        'Orientación técnica para el manejo nutricional en cáncer infantoadolescente',
    claves: ['desnutrición', 'nutrición', 'afecta', 'peso', 'bajar de peso'],
  ),
  PreguntaBase(
    id: 'alimentos-recomendados',
    categoria: 'Alimentación',
    pregunta: '¿Qué alimentos se recomiendan para los niños con cáncer?',
    respuesta:
        'Los lácteos aportan proteínas y calcio, se toleran bien (sobre todo sin lactosa) y son fundamentales para el crecimiento. Se recomiendan:\n• Leches pasteurizadas en envase tetra pak o en polvo, sin probióticos.\n• Quesos pasteurizados, solo fundidos en el horno a más de 180 °C.\n• Yogur batido pasteurizado, bajo en azúcar y sin probióticos.\n• Huevos cocidos (duros o revueltos).\n• Merengue cocido al horno.\n• Carnes de vacuno, conejo, caballo, pollo, pavo, pescados y mariscos bien cocidos.\n• Jamón de pechuga de pavo o pollo cocido, desgrasado, al vacío y no ahumado.\n• Panes envasados bajos en grasa.\n• Frutas crudas que se puedan lavar y pelar (naranja, pera, piña, plátano, melón, palta, manzana, durazno, pepino).\n• Frutas cocidas o en conserva.\n• Legumbres cocidas según tolerancia, en guisos y ensaladas.\n• Agua hervida, embotellada individual, o jugos e hidratantes en tetra pak.\n• Hielo hecho en casa con agua hervida o purificada.',
    fuente:
        'Orientación técnica para el manejo nutricional en cáncer infantoadolescente',
    contenidoRelacionadoId: 'alimentacion-durante-la-quimioterapia-infantil',
    claves: [
      'recomendados',
      'puede comer',
      'alimentos',
      'comida',
      'lácteos',
      'leche',
      'yogur',
      'huevo',
      'carne',
      'fruta',
      'pan',
      'legumbres',
    ],
  ),
  PreguntaBase(
    id: 'alimentos-evitar',
    categoria: 'Alimentación',
    pregunta: '¿Qué alimentos no se recomiendan en niños con cáncer?',
    respuesta:
        '• Leche cruda de origen animal.\n• Quesos añejados (roquefort, camembert, de cabra o de campo) sin pasteurizar.\n• Yogur de pajaritos (kéfir) con probióticos y shots de probióticos.\n• Huevos crudos o poco cocidos (a la copa, merengue suizo o crudo).\n• Carnes semicocidas (tipo roast beef) o crudas, ceviches y sushi.\n• Carnes y pescados ahumados.\n• Fiambres altos en grasa: jamón crudo, salame, chorizo, patés, arrollados.\n• Panes y cereales con hongos visibles.\n• Verduras fermentadas y escabechadas (pepinillos, zanahoria, cebolla, etc.).\n• Frutos secos a granel.\n• Agua cruda, bebidas azucaradas, té ahumado, agua de pozo o de fuentes naturales como ríos o manantiales.\n• Hielo comercial o de máquinas.\n• Miel de abeja cruda.\n• Repostería no preparada en casa.\n• Frutas crudas muy manipuladas: higos, brevas, níspero, frambuesas, frutillas, moras, arándanos, ciruelas, cerezas, uvas.',
    fuente:
        'Orientación técnica para el manejo nutricional en cáncer infantoadolescente',
    claves: [
      'evitar',
      'no puede comer',
      'prohibidos',
      'no recomendados',
      'crudo',
      'sushi',
      'ceviche',
      'embutidos',
      'miel',
      'kéfir',
      'probióticos',
      'frutillas',
    ],
  ),
  PreguntaBase(
    id: 'cuidados-alimentos',
    categoria: 'Alimentación',
    pregunta: '¿Qué cuidados hay que tener con los alimentos?',
    respuesta:
        'La alimentación debe cuidar la calidad, la inocuidad y la correcta manipulación de las preparaciones.\nAl comprar:\n• Prefiere marcas conocidas y supermercados grandes, donde se controla la temperatura y el vencimiento.\n• Revisa que el envase esté sellado y en buen estado, idealmente al vacío.\n• Los refrigerados deben estar fríos al tacto, y los congelados y refrigerados se recogen al final de la compra.\n• Descarta huevos con cáscara agrietada y alimentos que luzcan o huelan extraño.\n• No consumas comida callejera ni artesanal (queso de campo, sándwiches, fiambres, pastelería, mermelada casera).\n• Elige productos pasteurizados individuales, como leches y jugos en tetra pak.\nAl guardar:\n• Ordena los alimentos frescos en el refrigerador, rotulados, en envases separados y tapados, para evitar la contaminación cruzada.\n• Refrigera los huevos por no más de 30 días y lávalos antes de usarlos.\n• Descongela carne, pescado o aves en el refrigerador o el microondas, en un plato que recoja el líquido, nunca mucho tiempo a temperatura ambiente.\n• Guarda abarrotes, legumbres, aceites y enlatados en lugares frescos y secos, lejos de la humedad y de insectos.\n• Deja los alimentos el menor tiempo posible expuestos al ambiente, insectos, humedad o luz.',
    fuente:
        'Orientación técnica para el manejo nutricional en cáncer infantoadolescente',
    claves: [
      'cuidados',
      'comprar',
      'compra',
      'guardar',
      'almacenar',
      'refrigerador',
      'descongelar',
      'manipulación',
      'higiene',
    ],
  ),
  PreguntaBase(
    id: 'no-quiere-comer',
    categoria: 'Alimentación',
    pregunta: '¿Qué puedo hacer si mi hijo no quiere comer?',
    respuesta:
        '• Ofrece comidas pequeñas y frecuentes.\n• Adapta las texturas.\n• No lo fuerces a comer.\n• No uses suplementos sin recomendación médica.\nAdemás, ofrece alimentos con más calorías o enriquece los platos, ten a mano sus comidas favoritas, permite comer entre horas, haz que haga ejercicio moderado antes de comer y evita los alimentos bajos en calorías.',
    fuente:
        'Equipo de enfermería del proyecto OnCuidar y Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: [
      'no quiere comer',
      'apetito',
      'anorexia',
      'inapetencia',
      'no come',
      'rechaza',
    ],
  ),
  PreguntaBase(
    id: 'agua',
    categoria: 'Alimentación',
    pregunta: '¿Es mejor usar agua embotellada o basta con agua hervida?',
    respuesta:
        'Se recomienda agua hervida o embotellada. Durante y después del tratamiento, el cuerpo puede no ser capaz de protegerse de las infecciones, y el agua puede tener gérmenes aunque parezca limpia. Cuida la procedencia del agua para tomar, cocinar y cepillarse los dientes.',
    fuente: 'MedlinePlus, agua segura durante el tratamiento del cáncer',
    claves: ['agua', 'hervida', 'embotellada', 'llave', 'beber', 'tomar agua'],
  ),
  PreguntaBase(
    id: 'vitaminas',
    categoria: 'Alimentación',
    pregunta:
        '¿Puede tomar vitaminas, suplementos naturales o remedios caseros?',
    respuesta:
        'Antes de dar vitaminas o suplementos consulta siempre con su médico, para ver la dosis que le corresponde al niño.',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    claves: [
      'vitaminas',
      'suplementos',
      'remedios',
      'caseros',
      'naturales',
      'hierbas',
    ],
  ),
  PreguntaBase(
    id: 'gastrointestinales',
    categoria: 'Molestias digestivas',
    pregunta: '¿El tratamiento provoca problemas gastrointestinales?',
    respuesta:
        'Sí. La desnutrición suele estar presente al diagnóstico y empeora durante la terapia por el cáncer y la quimioterapia. Al final del tratamiento es más frecuente el exceso de peso, sobre todo en niños con tumores cerebrales o que reciben dosis altas de esteroides. Ambas situaciones se relacionan con más complicaciones. Pregunta por la molestia que tenga tu hijo (náuseas, diarrea, estreñimiento, llagas en la boca, boca seca) para ver los cuidados de cada una.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: [
      'gastrointestinales',
      'estómago',
      'digestivos',
      'guata',
      'intestino',
    ],
  ),
  PreguntaBase(
    id: 'nauseas-causa',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué causa las náuseas y los vómitos?',
    respuesta:
        'Muchos tratamientos los causan, pero los antieméticos que se dan antes de cada sesión ayudan a prevenirlos o reducirlos.\n• Quimioterapia: pueden empezar minutos u horas después, o al día siguiente. Suelen durar de 24 a 48 horas, aunque a veces hasta 7 días.\n• Radioterapia: unas horas después de cada sesión, y a veces por tres a cuatro semanas.\n• Terapia dirigida e inmunoterapia: durante o después del tratamiento. También se dan antieméticos antes.\n• Trasplante de médula ósea: por las dosis altas de quimioterapia o radioterapia previas. También pueden ser signo de complicaciones, como enfermedad de injerto contra huésped o infección.\n• Cirugía: por la anestesia y los analgésicos, por 24 a 48 horas.',
    fuente: 'Instituto Nacional del Cáncer, náuseas y vómitos',
    claves: ['causa', 'por qué', 'antieméticos', 'radioterapia', 'trasplante'],
  ),
  PreguntaBase(
    id: 'nauseas-cuidados',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué hago si tiene náuseas o vómitos?',
    respuesta:
        '• Ofrece comidas frecuentes y de poco volumen, a temperatura ambiente o frías.\n• Alimentos blandos, de sabor suave y sin condimentos.\n• Que beba entre comidas y no durante las comidas principales.\n• Que descanse después de comer, pero sin acostarse enseguida.\n• Ropa cómoda y suelta, que no apriete la cintura ni el abdomen.\n• Comidas 3 a 4 horas antes de la quimioterapia o radioterapia.\n• Evita olores intensos o desagradables.\n• Prueba técnicas de relajación y música.\n• Lleva un registro de cuándo siente náuseas, qué hizo y qué comió.\nSi los vómitos son persistentes, acude a urgencia.',
    fuente:
        'Revista Pediatría (Asunción), vol. 51 n.° 3 y Instituto Nacional del Cáncer, náuseas y vómitos',
    claves: [
      'náuseas',
      'vómitos',
      'vomita',
      'vomitar',
      'mareado',
      'asco',
      'devolver',
    ],
  ),
  PreguntaBase(
    id: 'mucositis',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué le doy si tiene llagas en la boca (mucositis)?',
    respuesta:
        'Sirve alimentos blandos, suaves y fáciles de masticar, en porciones pequeñas. Si es necesario, dieta líquida enriquecida: sopas, caldos, cremas de verduras, leche, batidos de fruta o yogur. Dalos a temperatura ambiente o fríos, ofrece helados de agua o cubitos de hielo y saca la corteza del pan. Evita alimentos irritantes, secos, duros, pegajosos, salados, condimentados, jugos ácidos y bebidas gaseosas.\nPara la higiene bucal: aplica anestésico tópico en las heridas antes de cada comida, cepilla los dientes después de cada comida con pasta para encías sensibles (sin mentol) y cepillo blando, y haz enjuagues con suero bicarbonatado o colutorios suaves.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    contenidoRelacionadoId: 'como-limpiar-los-dientes-durante-la-quimioterapia',
    claves: [
      'mucositis',
      'llagas',
      'aftas',
      'heridas',
      'boca',
      'encías',
      'duele la boca',
    ],
  ),
  PreguntaBase(
    id: 'diarrea',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué le doy si tiene diarrea?',
    respuesta:
        'Dale alimentos a temperatura ambiente y cambia la leche por yogur pasteurizado. Evita alimentos con mucha fibra (espinaca, acelga, brócoli), los que producen gases (repollo, coliflor, pimentón o cebolla crudos, legumbres, bebidas gaseosas), frutas como ciruela y kiwi, salsas, picantes, condimentos, bebidas endulzadas con fructosa o sorbitol, té, chocolate y frituras. Extrema la higiene.\nSi la diarrea es persistente, acude a urgencia.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: ['diarrea', 'deposiciones', 'suelto', 'caca líquida'],
  ),
  PreguntaBase(
    id: 'estrenimiento',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué hago si tiene estreñimiento?',
    respuesta:
        'Aumenta la fibra: verduras y frutas, mejor crudas, enteras y con piel, legumbres enteras o molidas, ensaladas como acompañamiento, frutas secas y productos integrales. Que tome abundante líquido durante el día, limite la leche, tenga un horario fijo para ir al baño y haga ejercicio moderado, como paseos cortos y frecuentes. Los alimentos o líquidos muy fríos o muy calientes estimulan el intestino.\nSi pasa más de 3 días sin evacuar, consulta: se considera una urgencia.',
    fuente:
        'Revista Pediatría (Asunción), vol. 51 n.° 3 y Guía de cuidado del niño en oncología',
    claves: ['estreñimiento', 'estreñido', 'no hace caca', 'fibra'],
  ),
  PreguntaBase(
    id: 'estrenimiento-urgencia',
    categoria: 'Molestias digestivas',
    pregunta: '¿Cuánto tiempo sin evacuar se considera una urgencia?',
    respuesta: 'Cuando pasa más de 3 días sin evacuar el intestino.',
    fuente: 'Guía de cuidado del niño en oncología',
    claves: ['días', 'evacuar', 'evacúa', 'no evacúa', 'cuánto tiempo'],
  ),
  PreguntaBase(
    id: 'boca-seca',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué hago si tiene la boca seca?',
    respuesta:
        'Ofrece alimentos húmedos, con sopas, salsas, mantequilla o lácteos, y agua antes y durante la comida para que trague mejor. Dale alimentos blandos, líquidos y bien cocidos, jugos cítricos o cubitos de hielo, y chicles o caramelos dulces o ácidos para estimular la saliva. Aplica vaselina en los labios, evita alimentos secos, ásperos, duros o irritantes y mantén una buena higiene bucal.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: ['boca seca', 'xerostomía', 'saliva', 'labios secos'],
  ),
  PreguntaBase(
    id: 'gusto',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué hago si le cambió el gusto o el olfato?',
    respuesta:
        'Sirve los alimentos fríos o a temperatura ambiente, usa hierbas aromáticas y especias para potenciar el sabor, adapta las preparaciones a sus gustos actuales y prefiere proteínas de sabor suave: pollo, pavo, lácteos y huevo. Mantén una buena higiene bucal, evita sabores amargos y usa cubiertos que no sean metálicos.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: ['gusto', 'sabor', 'olfato', 'sabe raro', 'metálico'],
  ),
  PreguntaBase(
    id: 'tragar',
    categoria: 'Molestias digestivas',
    pregunta: '¿Qué hago si le duele o le cuesta tragar?',
    respuesta:
        'Ofrece texturas blandas según sus preferencias, a temperatura fría o ambiente, en comidas fraccionadas, sin grumos, espinas ni huesos, y evita los alimentos irritantes.',
    fuente: 'Revista Pediatría (Asunción), vol. 51 n.° 3',
    claves: ['tragar', 'deglución', 'disfagia', 'odinofagia', 'atora'],
  ),
  PreguntaBase(
    id: 'esteroides',
    categoria: 'Efectos del tratamiento',
    pregunta:
        '¿Qué efectos puede tener el uso de esteroides y cómo manejarlos?',
    respuesta:
        'Efectos posibles:\n• Molestias físicas (dolor, náuseas).\n• Mucha hambre.\n• Dificultad para dormir.\n• Cambios de humor (tristeza, llanto, enojo).\n• Irritabilidad por cosas sin importancia.\n• Agresión verbal (gritos) o física (golpes, portazos).\n• No actuar como él mismo.\n• Problemas de atención.\n• Hiperactividad.\n• Confusión o alucinaciones.\nCómo sobrellevarlo:\n• Anímalo a expresar cómo se siente, con palabras, dibujos o jugando.\n• Háblale de manera clara y serena.\n• Evita situaciones nuevas y cambios en la rutina.\n• No intentes razonar con él durante una rabieta.\n• Ofrece comidas pequeñas.\n• Identifica las molestias físicas (dolor, náuseas, hambre).',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    claves: [
      'esteroides',
      'corticoides',
      'prednisona',
      'dexametasona',
      'humor',
      'rabietas',
      'irritable',
      'agresivo',
      'hambre',
    ],
  ),
  PreguntaBase(
    id: 'piel-sensibilidad',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿Cómo afecta el tratamiento a la piel?',
    respuesta:
        'Depende del tipo y la dosis de los medicamentos. Durante el tratamiento la piel puede resecarse o descamarse, volverse más sensible o irritarse con facilidad. Puede aparecer un salpullido o sensibilidad a productos que antes usaba. Algunos medicamentos causan una reacción parecida al acné, con espinillas o granos con punta blanca. También puede cambiar el color de la piel, con enrojecimiento u oscurecimiento.',
    fuente:
        'City of Hope, cuidado de la piel durante el tratamiento del cáncer',
    claves: [
      'piel',
      'reseca',
      'descama',
      'salpullido',
      'acné',
      'granos',
      'manchas',
      'enrojecimiento',
    ],
  ),
  PreguntaBase(
    id: 'piel-cuidado',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿Cómo cuidar la piel durante la quimioterapia?',
    respuesta:
        '• Cuídala desde el comienzo para que las reacciones no empeoren. Anota cualquier cambio y avísale al médico.\n• Aplica crema humectante cada día, o más seguido si la piel está seca. La vaselina pura es la mejor opción si tiene piel sensible o alergias.\n• Usa cremas sin perfume ni colorantes, en tubo y no en frasco dispensador, porque esas lociones son mayormente agua.\n• Prefiere duchas o baños breves con agua tibia.\n• Usa a diario protector solar de amplio espectro FPS 50 o más, y repítelo cada 60 a 90 minutos al sol.',
    fuente:
        'City of Hope, cuidado de la piel durante el tratamiento del cáncer',
    claves: [
      'cuidar la piel',
      'crema',
      'humectante',
      'vaselina',
      'protector solar',
      'bloqueador',
      'sol',
    ],
  ),
  PreguntaBase(
    id: 'boca-cancer',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿Cómo afecta el cáncer a la boca de los niños?',
    respuesta:
        'Las complicaciones en la boca son habituales, porque la quimioterapia y la radiación la afectan directamente. Las más comunes son mucositis, infecciones (bacterias, virus y hongos), problemas de las glándulas salivales, menos sentido del gusto, más caries, dificultad para abrir la boca (trismus) y osteonecrosis.\nEl tratamiento también puede afectar el crecimiento de dientes y cara, con secuelas como alteraciones dentarias y del crecimiento de la mandíbula, que afectan la función, la estética, la autoestima y la calidad de vida.\nEl cuidado bucal debe ser preventivo y terapéutico. El odontólogo, especialmente el odontopediatra, debe participar en todo el proceso, idealmente recuperando la salud bucal antes de iniciar el tratamiento.',
    fuente: 'Plan Nacional de Cáncer Infantoadolescente 2023-2028',
    contenidoRelacionadoId: 'como-limpiar-los-dientes-durante-la-quimioterapia',
    claves: ['dientes', 'dental', 'odontólogo', 'dentista', 'caries', 'bucal'],
  ),
  PreguntaBase(
    id: 'orina-color',
    categoria: 'Efectos del tratamiento',
    pregunta:
        '¿Es normal que la orina o el sudor cambien de color o tengan olor fuerte?',
    respuesta:
        'Algunos medicamentos contra el cáncer hacen que la orina cambie de color (anaranjado, rojo, verde o amarillo) o tenga olor fuerte o a medicamento por 24 a 72 horas. Pregunta al equipo de salud si los medicamentos de tu hijo causan esto.\nBeber mucho líquido ayuda a mantener un buen flujo de orina y a prevenir problemas, sobre todo con medicamentos que afectan los riñones y la vejiga: agua, jugos, caldos y sopas.',
    fuente: 'Johns Hopkins, cambios en la orina después de la quimioterapia',
    claves: ['orina', 'pipí', 'sudor', 'color', 'olor', 'riñones'],
  ),
  PreguntaBase(
    id: 'crecimiento',
    categoria: 'Efectos del tratamiento',
    pregunta:
        '¿Afectará el tratamiento el crecimiento y desarrollo de mi hijo?',
    respuesta:
        'Sí. La radioterapia y algunos tipos de quimioterapia pueden afectar el crecimiento y desarrollo de un niño. El impacto real depende del fármaco, la dosis, la zona tratada y la edad del paciente.',
    fuente:
        'American Cancer Society, efectos tardíos del tratamiento del cáncer infantil',
    claves: ['crecimiento', 'crecer', 'desarrollo', 'estatura', 'altura'],
  ),
  PreguntaBase(
    id: 'fertilidad',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿El tratamiento puede afectar la fertilidad?',
    respuesta:
        'Los tratamientos o cirugías que dañan los testículos o los ovarios pueden causar problemas de fertilidad. En niñas que ya menstrúan, pueden causar períodos irregulares o hacer que desaparezcan. Suele ser temporal, pero a veces dura más según la dosis.\nLos tratamientos antes de la pubertad tienen menos probabilidad de afectar la fertilidad futura. Aun así, conversa con el equipo de oncología sobre cómo podrían afectar las hormonas, el desarrollo sexual y la fertilidad, y pregunta si hay opciones para preservarla.',
    fuente:
        'American Cancer Society, efectos tardíos del tratamiento del cáncer infantil',
    claves: [
      'fertilidad',
      'infertilidad',
      'menstruación',
      'regla',
      'período',
      'pubertad',
      'hormonas',
    ],
  ),
  PreguntaBase(
    id: 'efectos-tardios',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿Cómo disminuir el riesgo de efectos tardíos?',
    respuesta:
        'No hay forma de eliminar todo el riesgo, pero a medida que crece se recomienda:\n• No usar tabaco y evitar el humo de otros.\n• Usar protección solar todos los días del año.\n• Evitar el alcohol.\n• No consumir drogas ni medicamentos recetados a otras personas.\n• Comer sano y limitar los ultraprocesados y bebidas azucaradas.\n• Mantenerse activo.\n• Tener las vacunas recomendadas, incluida la del VPH.\n• Ir a limpiezas y controles dentales.',
    fuente:
        'American Cancer Society, efectos tardíos del tratamiento del cáncer infantil',
    claves: [
      'tardíos',
      'sobreviviente',
      'después del cáncer',
      'futuro',
      'prevenir',
    ],
  ),
  PreguntaBase(
    id: 'cognitivos',
    categoria: 'Efectos del tratamiento',
    pregunta: '¿Tendrá problemas cognitivos después del tratamiento?',
    respuesta:
        'Los efectos cognitivos tardíos son cambios en la capacidad de memorizar, aprender y pensar. Son más probables en niños con tumores de cerebro o médula espinal, cánceres de cabeza y cuello y algunas leucemias, como la leucemia linfoblástica aguda, con radioterapia a la cabeza o ciertas quimioterapias, en niños muy pequeños al tratarse, con dosis muy altas o tratamientos largos.\nPueden tener más dificultad para:\n• Memorizar o recordar.\n• Aprender (escribir, deletrear, leer, vocabulario, matemáticas).\n• Pensar: concentrarse, terminar a tiempo, hacer tareas de varios pasos, resolver problemas y planificar.',
    fuente: 'Instituto Nacional del Cáncer, supervivencia en la infancia',
    contenidoRelacionadoId: 'efectos-cognitivos-del-tratamiento',
    claves: [
      'cognitivos',
      'memoria',
      'aprender',
      'colegio',
      'concentrarse',
      'atención',
      'estudio',
    ],
  ),
  PreguntaBase(
    id: 'dolor-escalas',
    categoria: 'Dolor',
    pregunta: '¿Cómo saber si mi hijo tiene dolor si no puede expresarlo?',
    respuesta:
        'Entre 1 mes y 3 años, o en niños que no colaboran, la más usada es la escala FLACC. Se valoran cinco aspectos de 0 a 2 y se suman (total de 0 a 10):\n• Cara: 0 sin expresión particular ni sonrisa. 1 mueca o ceño fruncido ocasional, retraído. 2 ceño fruncido frecuente o constante, mandíbula apretada, barbilla temblorosa.\n• Piernas: 0 posición normal o relajada. 1 inquietas o tensas. 2 da patadas o sube y baja las piernas.\n• Actividad: 0 acostado tranquilo, se mueve con facilidad. 1 se retuerce, cambia de postura, tenso. 2 se arquea, rígido o se sacude.\n• Llanto: 0 no llora. 1 gime o se queja de vez en cuando. 2 llanto constante, gritos o sollozos.\n• Consuelo: 0 contento y relajado. 1 se calma al tocarlo, arrullarlo o hablarle, se puede distraer. 2 cuesta consolarlo.\nDesde los 5 años se usan dibujos de caras (escala de Wong-Baker): el niño elige la que se parece a cómo le duele, de 0 (no hay dolor) a 10 (máximo dolor), pasando por 2 duele un poco, 4 duele algo más, 6 duele bastante y 8 duele mucho.\nTambién está la escala numérica (EVA), una línea del 1 al 10, y su versión con colores, más útil entre los 3 y 7 años.',
    fuente:
        'Asociación Española de Pediatría, cómo se evalúa el dolor en niños',
    claves: [
      'dolor',
      'duele',
      'escala',
      'flacc',
      'caritas',
      'llora',
      'quejido',
      'expresar',
    ],
  ),
  PreguntaBase(
    id: 'mascotas',
    categoria: 'Cuidados en casa',
    pregunta: '¿Puede mi hijo tener contacto con mascotas?',
    respuesta:
        '• Evita el contacto con animales desconocidos.\n• Si tienen mascotas, deben tener sus vacunas al día y una rutina de baño rigurosa.\n• Evita situaciones en que el niño pueda ser mordido o arañado, aunque los animales estén vacunados.\n• Lávense siempre las manos después de tocar animales.\n• No vayan al zoológico durante el tratamiento.',
    fuente: 'PINDA, Cuidados en casa',
    contenidoRelacionadoId: 'guia-de-higiene-para-ninos-con-cancer',
    claves: [
      'mascotas',
      'perro',
      'gato',
      'animales',
      'zoológico',
      'arañazo',
      'mordida',
    ],
  ),
  PreguntaBase(
    id: 'quimio-48-horas',
    categoria: 'Cuidados en casa',
    pregunta:
        '¿Qué cuidados tener en casa durante y después de la quimioterapia?',
    respuesta:
        'El cuerpo tarda al menos 48 horas en eliminar la mayor parte de la quimioterapia, principalmente por la orina y las heces, aunque también puede estar en el vómito, la saliva y el sudor. Pregunta al equipo cuánto tarda la que recibe tu hijo.\nAl usar el baño:\n• Si se puede, que los demás usen otro inodoro. Si no, limpia el asiento con toallita desinfectante después de cada uso.\n• Baja la tapa antes de tirar la cadena y, si el inodoro es de bajo flujo, tira dos veces.\n• Que se siente al usarlo, para evitar salpicaduras.\n• Lávense las manos con agua tibia y jabón.\nSi vomita:\n• En el inodoro, limpia las salpicaduras con toallita desinfectante y tira la cadena.\n• En un recipiente, vacíalo con cuidado en el inodoro, lávalo con agua caliente y jabón y bota también esa agua al inodoro.\nSi alguien toca sus fluidos:\n• Para limpiar, usa dos pares de guantes desechables y lávate las manos después, aunque los hayas usado.\n• Si hubo contacto con la piel, lava muy bien con agua tibia y jabón y avísale al médico en la próxima consulta.\nRopa sucia:\n• Lava en lavadora, no a mano, dos veces con agua caliente y detergente, separada del resto. Si no puedes lavarla enseguida, guárdala en una bolsa plástica sellada.\n• Pañales o toallas higiénicas: en bolsa plástica sellada, a la basura común.',
    fuente: 'American Cancer Society, seguridad durante la quimioterapia',
    claves: [
      '48 horas',
      'fluidos',
      'inodoro',
      'ropa',
      'guantes',
      'después de la quimio',
      'lavar',
    ],
  ),
  PreguntaBase(
    id: 'dosis-olvidada',
    categoria: 'Cuidados en casa',
    pregunta:
        '¿Qué pasa si se me olvida una dosis de la quimioterapia oral o del antibiótico?',
    respuesta:
        'Si se salta una dosis o la toma tarde, avísale al médico o a enfermería. Lo necesitan para saber si el tratamiento funciona y decidir si cambiar la cantidad o el horario.',
    fuente: 'American Cancer Society, quimioterapia oral',
    claves: [
      'olvidé',
      'olvida',
      'olvido',
      'dosis',
      'pastilla',
      'quimioterapia oral',
      'antibiótico',
      'remedio',
      'medicamento',
    ],
  ),
  PreguntaBase(
    id: 'vacunas',
    categoria: 'Cuidados en casa',
    pregunta: '¿Cuándo puede retomar sus vacunas después del tratamiento?',
    respuesta:
        'La revacunación después de la quimioterapia se hace a los 3 y 6 meses. Para la vacuna contra la varicela se recomienda que esté en remisión continua al menos 1 año.\nEn niños inmunocomprometidos no se administran las vacunas BCG ni polio oral. Sí se recomiendan meningococo (A, C, Y y W), Hib (después de los 5 años), neumococo conjugado (después de los 5 años) y polisacárido, e influenza estacional, además del calendario habitual.',
    fuente:
        'Revisión sobre vacunación después de la quimioterapia infantil (PMC7929592)',
    claves: [
      'vacunas',
      'vacuna',
      'vacunación',
      'calendario',
      'varicela',
      'influenza',
      'bcg',
    ],
  ),
  PreguntaBase(
    id: 'apoyo',
    categoria: 'Apoyo',
    pregunta: '¿Existe apoyo psicológico o una red de apoyo para la familia?',
    respuesta:
        'El programa PINDA tiene psicólogos y trabajadores sociales en sus centros, y las familias pueden pedir orientación y apoyo.\nTambién está la Fundación Nuestros Hijos, organización chilena sin fines de lucro creada en 1991 por padres de pacientes, que apoya a niños, niñas y adolescentes con cáncer, sus familias y sobrevivientes. Tiene un centro de rehabilitación oncológica pediátrica, apoyo médico y social, cuidados paliativos a domicilio, casas de acogida para familias de regiones, colegios hospitalarios, y apoyo psicológico, nutricional, odontológico y de transporte.',
    fuente: 'Equipo de enfermería del proyecto OnCuidar',
    contenidoRelacionadoId: 'guia-de-salud-mental-en-oncologia-infantil',
    claves: [
      'psicólogo',
      'psicooncología',
      'apoyo',
      'hermanos',
      'familia',
      'fundación',
      'nuestros hijos',
      'emocional',
      'ayuda',
    ],
  ),
];

MaterialEducativo? materialRelacionado(
  PreguntaBase pregunta,
  List<MaterialEducativo> catalogo,
) {
  final id = pregunta.contenidoRelacionadoId;
  if (id == null || id.isEmpty) return null;
  for (final material in catalogo) {
    if (material.id == id) return material;
  }
  return null;
}

const _idsMasFrecuentes = [
  'fiebre',
  'cuando-urgencia',
  'efectos-quimio-preocupantes',
  'petequias',
  'cateter-cuidados',
  'cateter-bano',
  'alimentos-recomendados',
  'alimentos-evitar',
  'agua',
  'no-quiere-comer',
  'nauseas-cuidados',
  'mucositis',
  'dolor-escalas',
  'mascotas',
  'vacunas',
  'apoyo',
];

List<PreguntaBase> preguntasMasFrecuentes() => [
  for (final p in preguntasFrecuentes)
    if (_idsMasFrecuentes.contains(p.id)) p,
];

List<String> categoriasDe(List<PreguntaBase> preguntas) =>
    preguntas.map((p) => p.categoria).toSet().toList();

List<PreguntaBase> preguntasDestacadas() {
  final vistas = <String>{};
  return [
    for (final p in preguntasFrecuentes)
      if (vistas.add(p.categoria)) p,
  ];
}

List<PreguntaBase> preguntasIniciales(Random azar, {int cantidad = 3}) =>
    (preguntasDestacadas()..shuffle(azar)).take(cantidad).toList();

List<PreguntaBase> sugerenciasDeSeguimiento(
  List<PreguntaBase> disponibles,
  String? categoria, {
  int maximo = 3,
}) {
  final mismas = disponibles.where((p) => p.categoria == categoria);
  final otras = disponibles.where((p) => p.categoria != categoria);
  return [...mismas, ...otras].take(maximo).toList();
}

List<String> categoriasDePreguntas() => categoriasDe(preguntasFrecuentes);

String normalizarTexto(String texto) {
  const reemplazos = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final caracter in texto.toLowerCase().runes) {
    final letra = String.fromCharCode(caracter);
    buffer.write(reemplazos[letra] ?? letra);
  }
  return buffer.toString().trim();
}
