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

tag_constitucional = Tag.create({ name: 'constitucional', tag_type_id: tag_type_materia.id })
tag_penal = Tag.create({ name: 'penal', tag_type_id: tag_type_materia.id })
tag_tributario = Tag.create({ name: 'tributario', tag_type_id: tag_type_materia.id })
tag_laboral = Tag.create({ name: 'laboral', tag_type_id: tag_type_materia.id })
tag_especiales_y_otras = Tag.create({ name: 'especiales y otras', tag_type_id: tag_type_materia.id })
tag_internacional_publico = Tag.create({ name: 'internacional publico', tag_type_id: tag_type_materia.id })
tag_civil = Tag.create({ name: 'civil', tag_type_id: tag_type_materia.id })
tag_mercantil = Tag.create({ name: 'tag_mercantil', tag_type_id: tag_type_materia.id })
tag_bancario = Tag.create({ name: 'bancario', tag_type_id: tag_type_materia.id })
tag_monetario = Tag.create({ name: 'monetario', tag_type_id: tag_type_materia.id })
tag_administrativo = Tag.create({ name: 'administrativo', tag_type_id: tag_type_materia.id })
tag_ambiental = Tag.create({ name: 'ambiental', tag_type_id: tag_type_materia.id })
tag_militar = Tag.create({ name: 'militar', tag_type_id: tag_type_materia.id })
tag_judicial = Tag.create({ name: 'judicial', tag_type_id: tag_type_materia.id })
tag_familia = Tag.create({ name: 'familia', tag_type_id: tag_type_materia.id })

# Tags de Creacion

tag_acuerdo_ejecutivo = Tag.create({ name: 'acuerdo ejecutivo', tag_type_id: tag_type_creacion.id })
tag_decreto_legislativo = Tag.create({ name: 'decreto legislativo', tag_type_id: tag_type_creacion.id })
tag_decreto_junta_militar = Tag.create({ name: 'decreto junta militar', tag_type_id: tag_type_creacion.id })
tag_tratado_internacional = Tag.create({ name: 'tratado internacional', tag_type_id: tag_type_creacion.id })
tag_asamblea_constituyente = Tag.create({ name: 'asamblea constituyente', tag_type_id: tag_type_creacion.id })

# Leyes

ley_codigo_civil = Law.create({ name: 'Codigo Civil', creation_number: '76-1906' })
ley_codigo_del_comercio = Law.create({ name: 'Codigo del Comercio', creation_number: '73-50' })
ley_codigo_del_trabajo = Law.create({ name: 'Codigo del Trabajo', creation_number: '189- 59' })
ley_codigo_penal = Law.create({ name: 'Codigo Penal', creation_number: '144-83' })
ley_codigo_procesal_penal = Law.create({ name: 'Codigo Procesal Penal', creation_number: '9-99-E' })
ley_constitucion_politica = Law.create({ name: 'Constitucion Politica', creation_number: '131 de 1982' })
ley_sobre_justicia = Law.create({ name: 'Sobre Justica', creation_number: '244-2003' })
ley_forestal_areas_protegidas_y_vida_silvestre = Law.create({ name: 'Ley forestal, areas protegidas y vida silvestre', creation_number: '' })
ley_de_creditos_usurarios = Law.create({ name: 'Ley de creditos usurarios', creation_number: '100-62' })
ley_de_instituciones_de_seguros_y_reaseguros = Law.create({ name: 'Ley de instituciones de seguros y reaseguros', creation_number: '22-2001' })
ley_del_banco_hondureño_del_cafe = Law.create({ name: 'Ley del banco hondureño del cafe', creation_number: '931 de 1972' })
ley_de_inversiones = Law.create({ name: 'Ley de inversiones', creation_number: '80-92' })
ley_de_propiedad_industrial = Law.create({ name: 'Ley de propiedad industrial', creation_number: '12-99' })
ley_del_impuesto_activo_neto = Law.create({ name: 'Ley del impuesto activo neto', creation_number: '137-94' })
ley_sobre_el_impuesto_sobre_ventas = Law.create({ name: 'Ley del impuesto sobre ventas', creation_number: '24 del 2004' })
ley_de_casas_de_cambio = Law.create({ name: 'Ley de casas de cambio', creation_number: '16-92' })
ley_de_contratacion_del_estado = Law.create({ name: 'Ley de Contratacion de Estado', creation_number: '74-2001' })
ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares = Law.create({ name: 'Ley de Control de Armas de Fuego Municiones Explosiones y Otros Similares', creation_number: '' })
ley_de_creacion_de_fondo_de_apoyo_a_la_policia = Law.create({ name: 'Ley de Creacion de Fondo de Apoyo a la Policia', creation_number: '64-98' })
ley_de_facilitacion_administrativa_para_la_recontruccion_nacional = Law.create({ name: 'Ley de Facilitacion Administrativa para la Recontruccion Nacional', creation_number: '284-98' })
ley_de_hidrocarburos = Law.create({ name: 'Ley de Hidrocarburos', creation_number: '194-84' })
ley_de_procedimiento_administrativo = Law.create({ name: 'Ley de Procedimiento Administrativo', creation_number: '152-87' })
ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion = Law.create({ name: 'Ley de Procedimiento para Contratacion de Financiamiento y Consultoria de Estudios de Preinversion', creation_number: '24-90' })
ley_de_simplificacion_administrativa = Law.create({ name: 'Ley de Simplificacion Administrativa', creation_number: '255-2002' })
ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos = Law.create({ name: 'Ley de Transplante y Extraccion de Organos y Tejidos Humanos', creation_number: '131 del 1997' })
ley_del_fondo_hondureno_de_preinversion = Law.create({ name: 'Ley del Fondo Hondureno de Preinversion', creation_number: '813 del 1979' })

# Tags de Materia de Leyes

LawTag.create({law_id: ley_codigo_civil.id, tag_id: tag_civil.id})
LawTag.create({law_id: ley_codigo_del_comercio.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_codigo_del_trabajo.id, tag_id: tag_laboral.id})
LawTag.create({law_id: ley_codigo_penal.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_codigo_procesal_penal.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_constitucion_politica.id, tag_id: tag_constitucional.id})
LawTag.create({law_id: ley_sobre_justicia.id, tag_id: tag_constitucional.id})
LawTag.create({law_id: ley_forestal_areas_protegidas_y_vida_silvestre.id, tag_id: tag_ambiental.id})
LawTag.create({law_id: ley_de_creditos_usurarios.id, tag_id: tag_bancario.id})
LawTag.create({law_id: ley_de_instituciones_de_seguros_y_reaseguros.id, tag_id: tag_bancario.id})
LawTag.create({law_id: ley_del_banco_hondureño_del_cafe.id, tag_id: tag_bancario.id})
LawTag.create({law_id: ley_de_inversiones.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_de_propiedad_industrial.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_del_impuesto_activo_neto.id, tag_id: tag_tributario.id})
LawTag.create({law_id: ley_sobre_el_impuesto_sobre_ventas.id, tag_id: tag_tributario.id})
LawTag.create({law_id: ley_de_casas_de_cambio.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_contratacion_del_estado.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_creacion_de_fondo_de_apoyo_a_la_policia.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_hidrocarburos.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_procedimiento_administrativo.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_simplificacion_administrativa.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_del_fondo_hondureno_de_preinversion.id, tag_id: tag_administrativo.id})

# Tags de Creacion de Leyes

LawTag.create({law_id: ley_codigo_civil.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_codigo_del_comercio.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_codigo_del_trabajo.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_codigo_penal.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_codigo_procesal_penal.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_constitucion_politica.id, tag_id: tag_asamblea_constituyente.id})
LawTag.create({law_id: ley_sobre_justicia.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_forestal_areas_protegidas_y_vida_silvestre.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_creditos_usurarios.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_instituciones_de_seguros_y_reaseguros.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_banco_hondureño_del_cafe.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_inversiones.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_propiedad_industrial.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_impuesto_activo_neto.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_sobre_el_impuesto_sobre_ventas.id, tag_id: tag_acuerdo_ejecutivo.id})
LawTag.create({law_id: ley_de_casas_de_cambio.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_contratacion_del_estado.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_creacion_de_fondo_de_apoyo_a_la_policia.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_hidrocarburos.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_procedimiento_administrativo.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_simplificacion_administrativa.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_fondo_hondureno_de_preinversion.id, tag_id: tag_decreto_legislativo.id})

ARGV = ['ScrappedLaws/Civil/ley_codigo_civil.json', ley_codigo_civil.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Mercantil/ley_codigo_del_comercio.json', ley_codigo_del_comercio.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Laboral/ley_codigo_del_trabajo.json', ley_codigo_del_trabajo.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Penal/ley_codigo_penal.json', ley_codigo_penal.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Penal/ley_codigo_procesal_penal.json', ley_codigo_procesal_penal.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Constitucional/ley_constitucion_politica.json', ley_constitucion_politica.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Constitucional/ley_sobre_justicia.json', ley_sobre_justicia.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Ambiental/ley_forestal_areas_protegidas_y_vida_silvestre.json', ley_forestal_areas_protegidas_y_vida_silvestre.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Bancario/ley_de_creditos_usurarios.json', ley_de_creditos_usurarios.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Bancario/ley_de_instituciones_de_seguros_y_reaseguros.json', ley_de_instituciones_de_seguros_y_reaseguros.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Bancario/ley_del_banco_hondureño_del_cafe.json', ley_del_banco_hondureño_del_cafe.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Mercantil/ley_de_inversiones.json', ley_de_inversiones.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Mercantil/ley_de_propiedad_industrial.json', ley_de_propiedad_industrial.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Tributario/ley_del_impuesto_activo_neto.json', ley_del_impuesto_activo_neto.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Tributario/ley_sobre_el_impuesto_sobre_ventas.json', ley_sobre_el_impuesto_sobre_ventas.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_casas_de_cambio.json', ley_de_casas_de_cambio.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_contratacion_del_estado.json', ley_de_contratacion_del_estado.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.json', ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_creacion_de_fondo_de_apoyo_a_la_policia.json', ley_de_creacion_de_fondo_de_apoyo_a_la_policia.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.json', ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_hidrocarburos.json', ley_de_hidrocarburos.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_procedimiento_administrativo.json', ley_de_procedimiento_administrativo.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.json', ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_simplificacion_administrativa.json', ley_de_simplificacion_administrativa.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.json', ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.id]
load 'ScrappedLaws/law_loader.rb'
ARGV = ['ScrappedLaws/Administrativo/ley_del_fondo_hondureno_de_preinversion.json', ley_del_fondo_hondureno_de_preinversion.id]
load 'ScrappedLaws/law_loader.rb'
