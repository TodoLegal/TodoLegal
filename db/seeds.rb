# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#######################
#### DocumentTypes ####
#######################

DocumentType.create(name: "Gaceta")
DocumentType.create(name: "Sección de Gaceta")
DocumentType.create(name: "Sentencia")
DocumentType.create(name: "Auto Acordado", alternative_name: "Circular")
DocumentType.create(name:"Comunicado")
DocumentType.create(name:"Formato")
DocumentType.create(name:"Otro")


########################
#### DatapointTypes ####
########################

DatapointType.create(name:"Issue id", priority: 1, description: "Este campo sirve para identificar al documento con el código que la institución lo creó. Algunos ejemplos de estos códigos son: 15-2020, 146-2022, 09/2022, Sesión No 3972.\n\nSi el código en la Gaceta lleva la palabra decreto o acuerdo, no se debe poner.\n\nSi se utiliza la descripción CERTIFICACIÓN, se debe buscar que número de sesión, acta, acuerdo o decreto se está certificando y eso es lo que se debe poner.")
DatapointType.create(name:"Name", priority: 8, description: "Este campo es opcional, tiene un máximo de 120 caracteres y sirve para identificar al documento de forma que sea entendido en lenguaje natural.\n\nEs otra forma de describir el documento aparte del código de emisión, ejemplo: Código Penal y Código Civil.")
DatapointType.create(name:"Description", priority: 3, description: "Este campo resume en 1,250 caracteres el contenido del documento. Sirve para que el usuario decida si lo quiere descargar o no.\n\nEs más extenso que la descripción corta y puede ser una transcripción textual, siempre y cuando abarque la mayor explicación del documento.")
DatapointType.create(name:"Short Description", priority: 2, description: "Este campo es crítico y sirve al usuario para conocer rápidamente sobre el contenido del documento. El usuario lo visualiza en el feed principal de Valid y debe comunicar en 250 caracteres el contenido del documento. Puede ser una transcripción textual.")
DatapointType.create(name:"Issuer", priority: 4, description: "Se utiliza para identificar la institución que emitió el documento.")
DatapointType.create(name:"Tema", priority: 5, description: "Este campo permite la mejor forma para la clasificación de la información y también permite ser usado por el usuario para seleccionar sus preferencias y recibir las notificaciones personalizadas. Procurar usar entre 2 ó 3 temas por documento.")
DatapointType.create(name:"Materia", priority: 6, description:"Este campo permite clasificar el documento en relación a la materia del derecho al que pertenece y sirve al usuario para escoger sus intereses y recibir notificaciones en base a ellas. Nunca más de 2 materias y el 95% de las veces usar solo 1 materia.\n\nUna de las materias más común es Derecho Administrativo. Esta se usa para la regulación de la administración pública, proyectos del estado o nombramiento de funcionarios.")
DatapointType.create(name:"Tipo de Acto", priority: 7, description: "Este campo determina el tipo de acto que realizó la institución. Los actos están definidos en múltiples leyes, entre ellas la Ley General de la Administración Pública")

##################
#### TagTypes ####
##################

tag_type_materia = TagType.create({ name: 'materia' })
tag_institucion = TagType.create(name: "Institución")
tag_forma_de_publicacion = TagType.create(name: "Forma de Publicación")
tag_tipo_de_acto = TagType.create(name: "Tipo de Acto")
tag_tema = TagType.create(name: "Tema")

##############
#### Tags ####
##############

# Materias

tag_constitucional = Tag.create({ name: 'Constitucional', tag_type_id: tag_type_materia.id })
tag_penal = Tag.create({ name: 'Penal', tag_type_id: tag_type_materia.id })
tag_tributario = Tag.create({ name: 'Tributario', tag_type_id: tag_type_materia.id })
tag_laboral = Tag.create({ name: 'Laboral', tag_type_id: tag_type_materia.id })
tag_especiales_y_otras = Tag.create({ name: 'Especiales y Otras', tag_type_id: tag_type_materia.id })
tag_internacional_publico = Tag.create({ name: 'Internacional Público', tag_type_id: tag_type_materia.id })
tag_civil = Tag.create({ name: 'Civil', tag_type_id: tag_type_materia.id })
tag_mercantil = Tag.create({ name: 'Mercantil', tag_type_id: tag_type_materia.id })
tag_administrativo = Tag.create({ name: 'Administrativo', tag_type_id: tag_type_materia.id })
tag_ambiental = Tag.create({ name: 'Ambiental', tag_type_id: tag_type_materia.id })
tag_militar = Tag.create({ name: 'Militar', tag_type_id: tag_type_materia.id })
tag_judicial = Tag.create({ name: 'Judicial', tag_type_id: tag_type_materia.id })
tag_familia = Tag.create({ name: 'Familia', tag_type_id: tag_type_materia.id })
tag_derechos_humanos = Tag.create({ name: 'Derechos Humanos', tag_type_id: tag_type_materia.id })
tag_propiedad_intelectual = Tag.create({ name: 'Propiedad Intelectual', tag_type_id: tag_type_materia.id })

# Institución

tag_poder_ejecutivo = Tag.create(name: "Poder Ejecutivo", tag_type_id: tag_institucion.id)
tag_congreso_nacional = Tag.create(name: "Congreso Nacional", tag_type_id: tag_institucion.id)
tag_junta_militar = Tag.create(name: "Junta Militar", tag_type_id: tag_institucion.id)
tag_asamblea_constituyente = Tag.create(name: "Asamblea Constituyente", tag_type_id: tag_institucion.id)
tag_cnbs = Tag.create(name: "CNBS", tag_type_id: tag_institucion.id)
tag_municipalidad_de_sps = Tag.create(name: "Municipalidad de SPS", tag_type_id: tag_institucion.id)
tag_senasa = Tag.create(name: "SENASA", tag_type_id: tag_institucion.id)
tag_aduana = Tag.create(name: "Aduana", tag_type_id: tag_institucion.id)
tag_cree = Tag.create(name: "CREE", tag_type_id: tag_institucion.id)
tag_enag = Tag.create(name: "ENAG", tag_type_id: tag_institucion.id)
tag_varios = Tag.create(name: "Varios", tag_type_id: tag_institucion.id)

# Forma de Publicación
tag_gaceta = Tag.create(name: "Gaceta", tag_type_id: tag_forma_de_publicacion.id)
tag_gaceta_municipal = Tag.create(name: "Gaceta Municipal", tag_type_id: tag_forma_de_publicacion.id)
tag_circular = Tag.create(name: "Circular", tag_type_id: tag_forma_de_publicacion.id)
tag_oficio = Tag.create(name: "Oficio", tag_type_id: tag_forma_de_publicacion.id)

# Tipo de Acto
tag_decreto = Tag.create(name: "Decreto", tag_type_id: tag_tipo_de_acto.id)
tag_acuerdo = Tag.create(name: "Acuerdo", tag_type_id: tag_tipo_de_acto.id)
tag_tratado_internacional = Tag.create(name: "Tratado Internacional", tag_type_id: tag_tipo_de_acto.id)
tag_resolucion = Tag.create(name: "Resolución", tag_type_id: tag_tipo_de_acto.id)
tag_sentencia = Tag.create(name: "Sentencia", tag_type_id: tag_tipo_de_acto.id)

# Tema
marcas = Tag.create(name: "Marcas", tag_type_id: tag_tema.id)
marcas = Tag.create(name: "Avisos Legales", tag_type_id: tag_tema.id)
marcas = Tag.create(name: "Licitaciones", tag_type_id: tag_tema.id)

###################
#### LawAccess ####
###################

law_access_pro = LawAccess.create(name: "Pro")
law_access_basic = LawAccess.create(name: "Básica")
law_access_todos = LawAccess.create(name: "Todos")

#####################
#### Permissions ####
#####################

permissions_admin = Permission.create(name: "Admin")
permissions_editor = Permission.create(name: "Editor")
permissions_pro = Permission.create(name: "Pro")

##############
#### Laws ####
##############

# Demo

law_demo = Law.create({ name: "Demo", creation_number: "2018-04", law_access_id: law_access_todos.id })
LawTag.create({law_id: law_demo.id, tag_id: Tag.find_by_name("Especiales y Otras").id})
LawTag.create({law_id: law_demo.id, tag_id: Tag.find_by_name("Resolución").id})
LawTag.create({law_id: law_demo.id, tag_id: Tag.find_by_name("Congreso Nacional").id})
LawTag.create({law_id: law_demo.id, tag_id: Tag.find_by_name("Circular").id})
LawTag.create({law_id: law_demo.id, tag_id: Tag.find_by_name("Sentencia").id})
Book.create(position:    0, number: "1", law_id: law_demo.id, name: "Ejemplo libro")
Title.create(position:   1, number: "1", law_id: law_demo.id, name: "Ejemplo título")
Chapter.create(position: 2, number: "1", law_id: law_demo.id, name: "Ejemplo capítulo")
Section.create(position: 3, number: "a", law_id: law_demo.id, name: "Ejemplo sección")
Article.create(position: 4, number: "1", law_id: law_demo.id, body: "Esta es una lista\n* A\n* B\n* C")
Section.create(position: 5, number: "b", law_id: law_demo.id, name: "Ejemplo sección")
Article.create(position: 6, number: "2", law_id: law_demo.id, body: "Marcando *negrita* e _itálica_.")
Book.create(position:    7, number: "2", law_id: law_demo.id, name: "Ejemplo libro #2")
Title.create(position:   8, number: "2", law_id: law_demo.id, name: "Ejemplo título #2")
Chapter.create(position: 9, number: "2", law_id: law_demo.id, name: "Ejemplo capítulo #2")
Section.create(position: 10, number: "a", law_id: law_demo.id, name: "Ejemplo sección")
Article.create(position: 11, number: "1", law_id: law_demo.id, body: "Ejemplo artículo.")
Section.create(position: 12, number: "b", law_id: law_demo.id, name: "Ejemplo sección")
Article.create(position: 13, number: "2", law_id: law_demo.id, body: "Otro ejemplo artículo.")

# Lorem Ipsum

law_lorem_ipsum = Law.create({ name: "Lorem Ipsum", creation_number: "2019-06", law_access_id: law_access_basic.id })
LawTag.create({law_id: law_lorem_ipsum.id, tag_id: Tag.find_by_name("Civil").id})
LawTag.create({law_id: law_lorem_ipsum.id, tag_id: Tag.find_by_name("CNBS").id})
LawTag.create({law_id: law_lorem_ipsum.id, tag_id: Tag.find_by_name("CREE").id})
Article.create(position: 0, number: "1", law_id: law_lorem_ipsum.id, body: "Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como texto de relleno en documentos electrónicos, quedando esencialmente igual al original. Fue popularizado en los 60s con la creación de las hojas 'Letraset', las cuales contenian pasajes de Lorem Ipsum, y más recientemente con software de autoedición, como por ejemplo Aldus PageMaker, el cual incluye versiones de Lorem Ipsum.")
Article.create(position: 1, number: "2", law_id: law_lorem_ipsum.id, body: "Al contrario del pensamiento popular, el texto de Lorem Ipsum no es simplemente texto aleatorio. Tiene sus raices en una pieza cl´sica de la literatura del Latin, que data del año 45 antes de Cristo, haciendo que este adquiera mas de 2000 años de antiguedad. Richard McClintock, un profesor de Latin de la Universidad de Hampden-Sydney en Virginia, encontró una de las palabras más oscuras de la lengua del latín, 'consecteur', en un pasaje de Lorem Ipsum, y al seguir leyendo distintos textos del latín, descubrió la fuente indudable. Lorem Ipsum viene de las secciones 1.10.32 y 1.10.33 de 'de Finnibus Bonorum et Malorum' (Los Extremos del Bien y El Mal) por Cicero, escrito en el año 45 antes de Cristo. Este libro es un tratado de teoría de éticas, muy popular durante el Renacimiento. La primera linea del Lorem Ipsum, 'Lorem ipsum dolor sit amet..', viene de una linea en la sección 1.10.32")
Article.create(position: 2, number: "3", law_id: law_lorem_ipsum.id, body: "Es un hecho establecido hace demasiado tiempo que un lector se distraerá con el contenido del texto de un sitio mientras que mira su diseño. El punto de usar Lorem Ipsum es que tiene una distribución más o menos normal de las letras, al contrario de usar textos como por ejemplo 'Contenido aquí, contenido aquí'. Estos textos hacen parecerlo un español que se puede leer. Muchos paquetes de autoedición y editores de páginas web usan el Lorem Ipsum como su texto por defecto, y al hacer una búsqueda de 'Lorem Ipsum' va a dar por resultado muchos sitios web que usan este texto si se encuentran en estado de desarrollo. Muchas versiones han evolucionado a través de los años, algunas veces por accidente, otras veces a propósito (por ejemplo insertándole humor y cosas por el estilo).")
Article.create(position: 3, number: "4", law_id: law_lorem_ipsum.id, body: "Hay muchas variaciones de los pasajes de Lorem Ipsum disponibles, pero la mayoría sufrió alteraciones en alguna manera, ya sea porque se le agregó humor, o palabras aleatorias que no parecen ni un poco creíbles. Si vas a utilizar un pasaje de Lorem Ipsum, necesitás estar seguro de que no hay nada avergonzante escondido en el medio del texto. Todos los generadores de Lorem Ipsum que se encuentran en Internet tienden a repetir trozos predefinidos cuando sea necesario, haciendo a este el único generador verdadero (válido) en la Internet. Usa un diccionario de mas de 200 palabras provenientes del latín, combinadas con estructuras muy útiles de sentencias, para generar texto de Lorem Ipsum que parezca razonable. Este Lorem Ipsum generado siempre estará libre de repeticiones, humor agregado o palabras no características del lenguaje, etc.")

# Las Reglas

law_las_reglas = Law.create({ name: "Las Reglas", creation_number: "2020-02", law_access_id: law_access_pro.id })
LawTag.create({law_id: law_las_reglas.id, tag_id: Tag.find_by_name("Constitucional").id})
LawTag.create({law_id: law_las_reglas.id, tag_id: Tag.find_by_name("Congreso Nacional").id})
LawTag.create({law_id: law_las_reglas.id, tag_id: Tag.find_by_name("Decreto").id})
Article.create(position: 0, number: "1", law_id: law_las_reglas.id, body: "El ahijado tiene estríctamente prohibido revelar la existencia o la tenencia de padrinos mágicos, de lo contrario, los perderá para siempre, olvidando todo lo vivido con ellos.")
Article.create(position: 1, number: "2", law_id: law_las_reglas.id, body: "Se le asignará un padrino mágico a los hijos de la especie dominante sobre la Tierra.")
Article.create(position: 2, number: "3", law_id: law_las_reglas.id, body: "Cualquier deseo deshecho entra al archivo personal de deseos desechos en el Mundo Mágico.")
Article.create(position: 3, number: "4", law_id: law_las_reglas.id, body: "Se abrirá juicio en caso de que el niño sea desagradecido por los deseos concedidos.")
Article.create(position: 4, number: "5", law_id: law_las_reglas.id, body: "Los padrinos mágicos sólo conceden deseos con la voz del niño al que fueron asignados. A menos que este no posea voz aun.")
Article.create(position: 5, number: "6", law_id: law_las_reglas.id, body: "Los padrinos mágicos sólo pueden conceder deseos a los niños. O a sus ahijados no niños que se comporten como tal.")
Article.create(position: 6, number: "7", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden decirle a su ahijado cuáles otros niños tienen padrinos mágicos. El ahijado debe descubrirlo por sí mismo.")
Article.create(position: 7, number: "8", law_id: law_las_reglas.id, body: "Si los niños están al poder del mundo, los padrinos mágicos volverán a mundo mágico.")
Article.create(position: 8, number: "9", law_id: law_las_reglas.id, body: "Si todos los padrinos mágicos del universo quieren al mismo ahijado deberán tener un encuentro de boxeo de traseros con magia en Texas.")
Article.create(position: 9, number: "0", law_id: law_las_reglas.id, body: "Sólo se sirve el desayuno hasta las 10:30 AM.")
Article.create(position: 10, number: "11", law_id: law_las_reglas.id, body: "Los padrinos dejarán al niño el día que éste diga la frase: 'Soy feliz y ya no necesito a mis padrinos mágicos'.")
Article.create(position: 11, number: "12", law_id: law_las_reglas.id, body: "Un padrino mágico no puede desaparecer por el deseo de otro ahijado mágico.")
Article.create(position: 12, number: "13", law_id: law_las_reglas.id, body: "Los padrinos mágicos sólo pueden ser prestados a otro niño si éste tiene el doble de las desdichas del niño al que tienen asignado.")
Article.create(position: 13, number: "14", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden interferir con el verdadero amor. Sin embargo, el falso amor no aplica para esta regla. Tampoco pueden hacer que alguien se enamore. Ni detener alguna carta de amor.")
Article.create(position: 14, number: "15", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden hacerle daño físico o matar a alguien.")
Article.create(position: 15, number: "16", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden ayudar al niño a ganar una competencia y no pueden ayudar a su ahijado en una elección o votación.")
Article.create(position: 16, number: "17", law_id: law_las_reglas.id, body: "Los padrinos mágicos no podrán falsificar documentos por más importante que sea.")
Article.create(position: 17, number: "18", law_id: law_las_reglas.id, body: "Los padrinos mágicos no deben conceder el deseo de que todos los días sea Navidad.")
Article.create(position: 18, number: "19", law_id: law_las_reglas.id, body: "Los padrinos mágicos NO pueden conceder deseos económicos (aparecer dinero) porque es falsificación y es un delito.")
Article.create(position: 19, number: "20", law_id: law_las_reglas.id, body: "El 'Hada de los Dientes' es la única que puede realizar todo tipo de magia dental. Morfeo es el único que puede realizar todo tipo de magia relacionado con el sueño. Cupido es el único que puede realizar todo tipo de magia amorosa. Don Papi es el único que puede hacer magia relacionada con la basura.")
Article.create(position: 20, number: "21", law_id: law_las_reglas.id, body: "Jorgen Von Strangulen puede hacer restitución de padrinos mágicos cambiando la regla por un castigo severo.")
Article.create(position: 21, number: "22", law_id: law_las_reglas.id, body: "Los deseos pedidos, serán cumplidos al pie de la letra y respetados. Además, la prioridad de los deseos es cronológica.")
Article.create(position: 22, number: "23", law_id: law_las_reglas.id, body: "No se deberá interferir con los anti-padrinos aunque así lo desee el niño.")
Article.create(position: 23, number: "24", law_id: law_las_reglas.id, body: "Los padrinos mágicos podrán renunciar a su cargo siempre y cuando las condiciones lo ameriten.")
Article.create(position: 24, number: "25", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden conseguir boletos para eventos a su ahijado si éstos están agotadas porque implica quitárselas a alguien que ya las había comprado y eso haría infeliz a esa persona.")
Article.create(position: 25, number: "26", law_id: law_las_reglas.id, body: "Las redes para mariposas son invulnerables ante la magia, ya que ellas atrapan cosas con alas.")
Article.create(position: 26, number: "27", law_id: law_las_reglas.id, body: "Habrá una inspección donde se evaluará el desempeño de los padrinos mágicos. Según ésta evaluación se sabrá cómo hacen su labor. Si fallan en dos de las tres áreas (felicidad, número de deseos y responsabilidad), tendrán que volver a la Magi-Academia.")
Article.create(position: 27, number: "28", law_id: law_las_reglas.id, body: "Sólo se le otorgará padrinos mágicos al niño que tenga una existencia miserable por razones de su vida.")
Article.create(position: 28, number: "29", law_id: law_las_reglas.id, body: "Los padrinos mágicos deben presentarse a la Certificación de coronas y entonación de varitas cada 3000 deseos en la Academia de magia.")
Article.create(position: 29, number: "30", law_id: law_las_reglas.id, body: "La magia no pueden matar a las cucarachas. Sino esfumándolas a otro lado.")
Article.create(position: 30, number: "31", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden interferir con los deseos que tengan más magia que ellos.")
Article.create(position: 31, number: "32", law_id: law_las_reglas.id, body: "Los padrinos mágicos deben enfrentar una reunión secreta y pasarla, de lo contrario sufrirán diferentes correctivos.")
Article.create(position: 32, number: "33", law_id: law_las_reglas.id, body: "Los Padrinos Mágicos deben obedecer los deseos pedidos por alguna parte de su ahijado.")
Article.create(position: 33, number: "34", law_id: law_las_reglas.id, body: "La magia no puede con los dragones.")
Article.create(position: 34, number: "35", law_id: law_las_reglas.id, body: "No se puede matar a los padres del ahijado.")
Article.create(position: 35, number: "36", law_id: law_las_reglas.id, body: "No se puede sacar a alguien de la cárcel, llevará muchos años liberarlos de la justicia, aún con mágia.")
Article.create(position: 36, number: "37", law_id: law_las_reglas.id, body: "La basura no puede ser eliminada con magia.")
Article.create(position: 37, number: "38", law_id: law_las_reglas.id, body: "Nadie (ahijados) puede viajar en el tiempo al 15 de Marzo de 1972 ni volver a ese año para interferir en la reelección el presidente Richard Nixon.")
Article.create(position: 38, number: "39", law_id: law_las_reglas.id, body: "Los Súper deseos son invulnerables a la magia.")
Article.create(position: 39, number: "40", law_id: law_las_reglas.id, body: "Los padrinos mágicos solo pueden ser vistos por el niño que fueron asignados, o por otros niños con padrinos mágicos.")
Article.create(position: 40, number: "41", law_id: law_las_reglas.id, body: "Si el niño no cree en la magia, los padrinos mágicos deben irse.")
Article.create(position: 41, number: "42", law_id: law_las_reglas.id, body: "Sólo quien pide sus deseos puede deshacerlos. A menos que se lo pidan a Santa Claus")
Article.create(position: 42, number: "43", law_id: law_las_reglas.id, body: "Solamente cuando el ahijado u ahijada dice la palabra 'deseo' los padrinos mágicos deberán cumplir, los padrinos estarán obligados a cumplir el deseo.")
Article.create(position: 43, number: "44", law_id: law_las_reglas.id, body: "No se puede pedir que nazca un Tom Cruise.")
Article.create(position: 44, number: "45", law_id: law_las_reglas.id, body: "Si el ahijado(a) maltrata a sus padrinos mágicos estos pueden darse la libertad de abandonar o renunciar a ser sus padrinos.")
Article.create(position: 45, number: "46", law_id: law_las_reglas.id, body: "Cuando el ahijado desea ser Maestro en algún arte o algo, se deben respetar las reglas de lo que quiere ser.")
Article.create(position: 46, number: "47", law_id: law_las_reglas.id, body: "Un padrino mágico no puede controlar o usar la varita de otro padrino mágico. Excepto en casos de emergencia")
Article.create(position: 47, number: "48", law_id: law_las_reglas.id, body: "Está prohibido para un padrino mágico devolver la memoria a su 'ex ahijado' cuando este los pierde por romper una de las reglas.")
Article.create(position: 48, number: "49", law_id: law_las_reglas.id, body: "Los padrinos mágicos no pueden concederle deseos a su ahijado si ellos no saben que cosa pide o a qué/quien se refiere.")
Article.create(position: 49, number: "50", law_id: law_las_reglas.id, body: "Los padrinos mágicos no podrán revivir a un muerto, ni aunque lo desee el niño.")
Article.create(position: 50, number: "51", law_id: law_las_reglas.id, body: "El ahijado puede tener su propia varita pero esta solo puede cumplir 10 deseos.")
Article.create(position: 51, number: "52", law_id: law_las_reglas.id, body: "Si el ahijado tiene padrinos mágicos en vez de un solo padrino, los deseos sólo se pueden cumplir si los dos padrinos están presentes y usan su varita.")
Article.create(position: 52, number: "53", law_id: law_las_reglas.id, body: "El Ahijado puede desear que los padrinos le concedan deseos a alguien más. Siempre y cuando no se pase de las 24 horas")
Article.create(position: 53, number: "54", law_id: law_las_reglas.id, body: "Sí existiera un niño llamado Timmy Turner que hubiera conservado y amado a sus padrinos por trece años; haber salvado el Mundo Mágico en más de una ocasión; y si prometiere pedir deseos, sólo para los demás y nunca para propósitos egoístas, entonces él podía quedarse con sus padrinos.")

###################
#### Documents ####
###################

# Ejemplo Titulo Prueba A

document_a = Document.create(
  url: "https://todolegal.app/documents/1-ejemplo-a",
  name: "Ejemplo Titulo Prueba A",
  publication_date: Date.yesterday,
  publication_number: "Acuerdo No. CN-006-2018",
  description: "Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como texto de relleno en documentos electrónicos, quedando esencialmente igual al original. Fue popularizado en los 60s con la creación de las hojas 'Letraset', las cuales contenian pasajes de Lorem Ipsum, y más recientemente con software de autoedición, como por ejemplo Aldus PageMaker, el cual incluye versiones de Lorem Ipsum."
)

IssuerDocumentTag.create(document_id: document_a.id, tag_id: Tag.find_by_name("Congreso Nacional").id)

DocumentTag.create({document_id: document_a.id, tag_id: Tag.find_by_name("Laboral").id})
DocumentTag.create({document_id: document_a.id, tag_id: Tag.find_by_name("Poder Ejecutivo").id})
DocumentTag.create({document_id: document_a.id, tag_id: Tag.find_by_name("Gaceta").id})

# Ejemplo Titulo Prueba B

document_b = Document.create(
  url: "https://todolegal.app/documents/1-ejemplo-a",
  name: "Otro Ejemplo Titulo Prueba B",
  publication_date: Date.today,
  publication_number: "Acuerdo No. CN-006-2018",
  description: "Al contrario del pensamiento popular, el texto de Lorem Ipsum no es simplemente texto aleatorio. Tiene sus raices en una pieza cl´sica de la literatura del Latin, que data del año 45 antes de Cristo, haciendo que este adquiera mas de 2000 años de antiguedad. Richard McClintock, un profesor de Latin de la Universidad de Hampden-Sydney en Virginia, encontró una de las palabras más oscuras de la lengua del latín, 'consecteur', en un pasaje de Lorem Ipsum, y al seguir leyendo distintos textos del latín, descubrió la fuente indudable. Lorem Ipsum viene de las secciones 1.10.32 y 1.10.33 de 'de Finnibus Bonorum et Malorum' (Los Extremos del Bien y El Mal) por Cicero, escrito en el año 45 antes de Cristo. Este libro es un tratado de teoría de éticas, muy popular durante el Renacimiento. La primera linea del Lorem Ipsum, 'Lorem ipsum dolor sit amet..', viene de una linea en la sección 1.10.32."
)

IssuerDocumentTag.create(document_id: document_b.id, tag_id: Tag.find_by_name("CNBS").id)

DocumentTag.create({document_id: document_b.id, tag_id: Tag.find_by_name("Aduana").id})
DocumentTag.create({document_id: document_b.id, tag_id: Tag.find_by_name("SENASA").id})
DocumentTag.create({document_id: document_b.id, tag_id: Tag.find_by_name("Circular").id})

DocumentRelationship.create({document_1_id: document_a.id, document_2_id: document_b.id, relationship: "belongs to"})