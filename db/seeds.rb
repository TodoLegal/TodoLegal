# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Tip de tags

tag_type_materia = TagType.create({ name: 'materia' })
tag_type_creacion = TagType.create({ name: 'creacion' })

# Tags de Materias

tag_constitucional = Tag.create({ name: 'Constitucional', tag_type_id: tag_type_materia.id })
tag_penal = Tag.create({ name: 'Penal', tag_type_id: tag_type_materia.id })
tag_tributario = Tag.create({ name: 'Tributario', tag_type_id: tag_type_materia.id })
tag_laboral = Tag.create({ name: 'Laboral', tag_type_id: tag_type_materia.id })
tag_especiales_y_otras = Tag.create({ name: 'Especiales y Otras', tag_type_id: tag_type_materia.id })
tag_internacional_publico = Tag.create({ name: 'Internacional Público', tag_type_id: tag_type_materia.id })
tag_civil = Tag.create({ name: 'Civil', tag_type_id: tag_type_materia.id })
tag_mercantil = Tag.create({ name: 'Mercantil', tag_type_id: tag_type_materia.id })
tag_bancario = Tag.create({ name: 'Bancario', tag_type_id: tag_type_materia.id })
tag_monetario = Tag.create({ name: 'Monetario', tag_type_id: tag_type_materia.id })
tag_administrativo = Tag.create({ name: 'Administrativo', tag_type_id: tag_type_materia.id })
tag_ambiental = Tag.create({ name: 'Ambiental', tag_type_id: tag_type_materia.id })
tag_militar = Tag.create({ name: 'Militar', tag_type_id: tag_type_materia.id })
tag_judicial = Tag.create({ name: 'Judicial', tag_type_id: tag_type_materia.id })
tag_familia = Tag.create({ name: 'Familia', tag_type_id: tag_type_materia.id })
tag_derechos_humanos = Tag.create({ name: 'Derechos Humanos', tag_type_id: tag_type_materia.id })


# Tags de Creacion

tag_acuerdo_ejecutivo = Tag.create({ name: 'Acuerdo Ejecutivo', tag_type_id: tag_type_creacion.id })
tag_decreto_ejecutivo = Tag.create({ name: 'Decreto Ejecutivo', tag_type_id: tag_type_creacion.id })
tag_decreto_legislativo = Tag.create({ name: 'Decreto Legislativo', tag_type_id: tag_type_creacion.id })
tag_decreto_junta_militar = Tag.create({ name: 'Decreto Junta Militar', tag_type_id: tag_type_creacion.id })
tag_tratado_internacional = Tag.create({ name: 'Tratado Internacional', tag_type_id: tag_type_creacion.id })
tag_asamblea_constituyente = Tag.create({ name: 'Asamblea Constituyente', tag_type_id: tag_type_creacion.id })
tag_resolucion = Tag.create({ name: 'Resolucion', tag_type_id: tag_type_creacion.id })
tag_acuerdo_ministerial = Tag.create({ name: 'Acuerdo Ministerial', tag_type_id: tag_type_creacion.id })

# Law Accesses

law_access_pro = LawAccess.create(name: "Pro")
law_access_basic = LawAccess.create(name: "Básica")

# Permissions

permissions_admin = Permission.create(name: "Admin")
permissions_pro = Permission.create(name: "Pro")