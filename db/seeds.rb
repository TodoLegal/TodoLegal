# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

tag_type_materia = TagType.create({ name: 'materia' })

tag_constitucional = Tag.create({ name: 'constitucional', tag_type_id: tag_type_materia.id })
tag_penal = Tag.create({ name: 'penal', tag_type_id: tag_type_materia.id })
tag_tributario = Tag.create({ name: 'tributario', tag_type_id: tag_type_materia.id })
tag_laboral = Tag.create({ name: 'laboral', tag_type_id: tag_type_materia.id })
tag_especiales_y_otras = Tag.create({ name: 'especiales y otras', tag_type_id: tag_type_materia.id })
tag_internacional_publico = Tag.create({ name: 'internacional publico', tag_type_id: tag_type_materia.id })
tag_civil = Tag.create({ name: 'civil', tag_type_id: tag_type_materia.id })
tag_comercial = Tag.create({ name: 'comercial', tag_type_id: tag_type_materia.id })
tag_bancario = Tag.create({ name: 'bancario', tag_type_id: tag_type_materia.id })
tag_monetario = Tag.create({ name: 'monetario', tag_type_id: tag_type_materia.id })
tag_administrativo = Tag.create({ name: 'administrativo', tag_type_id: tag_type_materia.id })
tag_ambiental = Tag.create({ name: 'ambiental', tag_type_id: tag_type_materia.id })
tag_militar = Tag.create({ name: 'militar', tag_type_id: tag_type_materia.id })
tag_judicial = Tag.create({ name: 'judicial', tag_type_id: tag_type_materia.id })
tag_familia = Tag.create({ name: 'familia', tag_type_id: tag_type_materia.id })

ley_codigo_civil = Law.create({ name: 'Codigo Civil' })
ley_codigo_del_comercio = Law.create({ name: 'Codigo del Comercio' })
ley_codigo_del_trabajo = Law.create({ name: 'Codigo del Trabajo' })
ley_codigo_penal = Law.create({ name: 'Codigo Penal' })
ley_codigo_procesal_penal = Law.create({ name: 'Codigo Procesal Penal' })
ley_constitucion_politica = Law.create({ name: 'Constitucion Politica' })
ley_sobre_justicia = Law.create({ name: 'Sobre Justica' })

LawTag.create({law_id: ley_codigo_civil.id, tag_id: tag_civil.id})
LawTag.create({law_id: ley_codigo_del_comercio.id, tag_id: tag_comercial.id})
LawTag.create({law_id: ley_codigo_del_trabajo.id, tag_id: tag_laboral.id})
LawTag.create({law_id: ley_codigo_penal.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_codigo_procesal_penal.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_constitucion_politica.id, tag_id: tag_constitucional.id})
LawTag.create({law_id: ley_sobre_justicia.id, tag_id: tag_constitucional.id})