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
ley_codigo_de_familia = Law.create({name: 'Codigo de Familia', creation_number: '76-84'})
ley_de_la_jurisdiccion_de_lo_contencioso_administrativo = Law.create({name: 'Ley de la Jurisdicción de lo Contencioso Administrativo', creation_number: '189-87'})
ley_de_municipalidades = Law.create({name: 'Ley de Municipalidades', creation_number: '134-30'})
ley_de_propiedad = Law.create({name: 'Ley de Propiedad', creation_number: '82-2004'})
ley_general_de_la_administracion_publica = Law.create({name: 'Ley General de la Administración Pública', creation_number: '146-86'})
ley_de_organizacion_y_atribucion_a_los_tribunales = Law.create({name: 'Ley de Organización y Atribuciones de los Tribunales (LOAT)', creation_number: '76-1998'})
ley_del_impuesto_sobre_renta = Law.create({name: 'Ley del Impuesto Sobre la Renta',creation_number: '25-2004'})
ley_codigo_procesal_civil = Law.create({ name: 'Codigo Procesal Civil', creation_number: '211-2006' })
ley_del_impuesto_sobre_ventas = Law.create({ name: 'Ley del Impuesto Sobre Ventas', creation_number: '24-1994' })
ley_cauca = Law.create({ name: 'Código Aduanero Uniforme Centroamericano CAUCA', creation_number: '023-2003' })
ley_codigo_tributario = Law.create({ name: 'Código Tributario', creation_number: '170-2016' })
ley_constitutiva_de_la_empresa_nacional_de_energia_electrica = Law.create({ name: 'Ley Constitutiva de la Empresa Nacional de Energía Eléctrica', creation_number: '48-1957' })
ley_de_apoyo_a_la_micro_y_pequena_empresa = Law.create({name: 'Ley de Apoyo a la Micro y Pequeña Empresa', creation_number: '145-2018'})
ley_de_creacion_del_consejo_nacional_contra_narcotrafico = Law.create({name: 'Ley de Creación del Consejo Nacional Contra el Narcotráfico', creation_number: '35-90'})
ley_derecho_de_autor_y_derechos_conexos = Law.create({name: 'Ley de Derecho de Autor y Derechos Conexos', creation_number: '4-99-E'})
ley_de_disponibiilidad_emergente_de_activos_incautados = Law.create({name: 'Ley de Disponibilidad Emergente de Activos Incautados', creation_number: '235-2010'})
ley_de_fomento_al_turismo = Law.create({name: 'Ley de Fomento al Turismo', creation_number: '68-2017'})
ley_de_garantias_mobiliarias = Law.create({name: 'Ley de Garantías Mobiliarias', creation_number: '182-2009'})
ley_de_inquilinato = Law.create({name: 'Ley de Inquilinato', creation_number: '50-1966'})
ley_de_la_policia_militar_del_orden_publico = Law.create({name: 'Ley de la Policía Militar del Orden Publico', creation_number: '168-2013'})
ley_zona_libre_turistica_islas_de_la_bahia = Law.create({name: 'Ley de la Zona Libre Turística del Departamento de Islas de la Bahía    ', creation_number: '181-2006'})
ley_de_migracion_y_extranjeria = Law.create({name: 'Ley de Migración y Extranjería', creation_number: '208-2003'})
ley_de_promocion_a_la_generacion_de_energia_electrica_con_recursos_renovables = Law.create({name: 'Ley de Promoción a la Generación de Energía Eléctrica con Recursos Renovables', creation_number: '70-2007'})
ley_proteccion_al_consumidor = Law.create({name: 'Ley de Protección al Consumidor', creation_number: '24-2008'})
ley_proteccion_de_funcionarios_y_exfuncionarios_riesgo_extraordinario = Law.create({name: 'Ley De Protección Especial de Funcionarios y Exfuncionarios En Riesgo Extraordinario', creation_number: '323-2013'})
ley_de_regulacion_actividades_y_profesiones_no_financieras_designadas = Law.create({name: 'Ley De Regulación de Actividades y Profesiones No Financieras Designadas', creation_number: '131-2014'})
ley_de_transito = Law.create({name: 'Ley de Transito', creation_number: '205-2005'})
ley_transporte_terreste_de_honduras = Law.create({name: 'Ley de Transporte Terrestre de Honduras', creation_number: '155-2015'})
ley_del_programa_para_la_consolidacion_de_deudas_trabajador_hondureno = Law.create({name: 'Ley del Programa para la Consolidación de Deudas Trabajador Hondureño', creation_number: '34-2013'})
ley_del_registro_nacional_de_las_personas = Law.create({name: 'Ley del Registro Nacional de las Personas ', creation_number: '62-2004'})
ley_del_seguro_social = Law.create({name: 'Ley del Seguro Social', creation_number: '80-2001'})
ley_del_sistema_nacional_de_emergencia = Law.create({name: 'Ley Del Sistema Nacional De Emergencia', creation_number: '58-2015'})
ley_electoral_y_de_las_organizaciones_politicas = Law.create({name: 'Ley Electoral y de las Organizaciones Políticas', creation_number: '44-2004'})

ley_especial_del_consejo_nacional_de_defensa = Law.create({name: 'Ley Especial del Consejo Nacional de Defensa y Seguridad', creation_number: '239-2011'})
ley_especial_para_la_depuracion_policial = Law.create({name: 'Ley Especial para la Depuración Policial', creation_number: '89-2012'})
ley_especial_para_simplificacion_de_procedimientos_de_inversion_en_infraestructura_publica = Law.create({name: 'Ley Especial para Simplificación de Procedimientos de Inversión en Infraestructura Publica', creation_number: '58-2011'})
ley_especial_reguladora_de_proyectos_publicos_de_energia_renovable = Law.create({name: 'Ley Especial Reguladora de Proyectos Públicos de Energía Renovable', creation_number: '279-2010'})
ley_general_de_la_industria_electrica =  Law.create({name: 'Ley General De La Industria Eléctrica ', creation_number: '404-2013'})
ley_marco_de_politicas_publicas_en_materia_social = Law.create({name: 'Ley Marco de Políticas Publicas en Materia Social', creation_number: '38-2011'})
ley_recauca = Law.create({name: 'Reglamento del Código Aduanero Uniforme Centroamericano RECAUCA', creation_number: 'Resolución 024-2008'})
ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo = Law.create({name: 'Ley Especial de Fomento para las Organizaciones No Gubernamentales de Desarrollo ONGD', creation_number: '32-2011'})
ley_general_de_la_superintendencia_para_la_aplicacion_de_pruebas_de_evaluacion_de_confianza = Law.create({name: 'Ley General de la Superintendencia para la Aplicación de Pruebas de Evaluación de Confianza', creation_number: '254-2013'})
ley_especial_de_intervencion_de_comunicaciones_privadas = Law.create({name: 'Ley Especial de Intervención de Comunicaciones Privadas', creation_number: '243-2011'})
ley_especial_para_el_ejercicio_del_sufragio_de_los_hondurenos_en_el_exterior = Law.create({name: 'Ley Especial para el Ejercicio del Sufragio de los Hondureños en el Exterior', creation_number: '72-2001'})
ley_especial_que_regula_el_plesbicito_y_el_referendum = Law.create({name: 'Ley Especial que Regula el Plebiscito y el Referéndum', creation_number: '135-2009'})

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
LawTag.create({law_id: ley_codigo_de_familia.id, tag_id: tag_familia.id})
LawTag.create({law_id: ley_de_la_jurisdiccion_de_lo_contencioso_administrativo.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_municipalidades.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_propiedad.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_general_de_la_administracion_publica.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_organizacion_y_atribucion_a_los_tribunales.id, tag_id: tag_judicial.id})
LawTag.create({law_id: ley_del_impuesto_sobre_renta.id, tag_id: tag_tributario.id})
LawTag.create({law_id: ley_codigo_procesal_civil.id, tag_id: tag_civil.id})
LawTag.create({law_id: ley_del_impuesto_sobre_ventas.id, tag_id: tag_tributario.id})
LawTag.create({law_id: ley_cauca.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_codigo_tributario.id, tag_id: tag_tributario.id})
LawTag.create({law_id: ley_constitutiva_de_la_empresa_nacional_de_energia_electrica.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_apoyo_a_la_micro_y_pequena_empresa.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_de_creacion_del_consejo_nacional_contra_narcotrafico.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_derecho_de_autor_y_derechos_conexos.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_disponibiilidad_emergente_de_activos_incautados.id, tag_id: tag_penal.id})
LawTag.create({law_id: ley_de_fomento_al_turismo.id, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_de_garantias_mobiliarias.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_de_inquilinato.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_la_policia_militar_del_orden_publico.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_zona_libre_turistica_islas_de_la_bahia.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_de_migracion_y_extranjeria.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_promocion_a_la_generacion_de_energia_electrica_con_recursos_renovables.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_proteccion_al_consumidor.id, tag_id: tag_mercantil.id})
LawTag.create({law_id: ley_proteccion_de_funcionarios_y_exfuncionarios_riesgo_extraordinario.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_de_regulacion_actividades_y_profesiones_no_financieras_designadas.id, tag_id: tag_bancario.id})
LawTag.create({law_id: ley_de_transito.id, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_transporte_terreste_de_honduras.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_del_programa_para_la_consolidacion_de_deudas_trabajador_hondureno.id, tag_id: tag_laboral.id})
LawTag.create({law_id: ley_del_registro_nacional_de_las_personas.id, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_del_seguro_social.id, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_del_sistema_nacional_de_emergencia.id, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_electoral_y_de_las_organizaciones_politicas.id, tag_id: tag_constitucional.id})

LawTag.create({law_id: ley_especial_del_consejo_nacional_de_defensa, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_especial_para_la_depuracion_policial, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_especial_para_simplificacion_de_procedimientos_de_inversion_en_infraestructura_publica, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_especial_reguladora_de_proyectos_publicos_de_energia_renovable, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_general_de_la_industria_electrica, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_marco_de_politicas_publicas_en_materia_social, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_recauca, tag_id: tag_administrativo.id})
LawTag.create({law_id: ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_general_de_la_superintendencia_para_la_aplicacion_de_pruebas_de_evaluacion_de_confianza, tag_id: tag_especiales_y_otras.id})
LawTag.create({law_id: ley_especial_de_intervencion_de_comunicaciones_privadas, tag_id: tag_penal.id})
LawTag.create({law_id: ley_especial_para_el_ejercicio_del_sufragio_de_los_hondurenos_en_el_exterior, tag_id: tag_constitucional.id})
LawTag.create({law_id: ley_especial_que_regula_el_plesbicito_y_el_referendum, tag_id: tag_constitucional.id})


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
LawTag.create({law_id: ley_codigo_de_familia.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_la_jurisdiccion_de_lo_contencioso_administrativo.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_municipalidades.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_propiedad.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_general_de_la_administracion_publica.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_organizacion_y_atribucion_a_los_tribunales.id, tag_id: tag_acuerdo_ejecutivo.id})
LawTag.create({law_id: ley_del_impuesto_sobre_renta.id, tag_id: tag_acuerdo_ejecutivo.id})
LawTag.create({law_id: ley_codigo_procesal_civil.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_impuesto_sobre_ventas.id, tag_id: tag_acuerdo_ejecutivo.id})
LawTag.create({law_id: ley_cauca.id, tag_id: tag_tratado_internacional.id})
LawTag.create({law_id: ley_codigo_tributario.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_constitutiva_de_la_empresa_nacional_de_energia_electrica.id, tag_id: tag_decreto_junta_militar.id})
LawTag.create({law_id: ley_de_apoyo_a_la_micro_y_pequena_empresa.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_creacion_del_consejo_nacional_contra_narcotrafico.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_derecho_de_autor_y_derechos_conexos.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_disponibiilidad_emergente_de_activos_incautados.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_fomento_al_turismo.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_garantias_mobiliarias.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_inquilinato.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_la_policia_militar_del_orden_publico.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_zona_libre_turistica_islas_de_la_bahia.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_migracion_y_extranjeria.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_promocion_a_la_generacion_de_energia_electrica_con_recursos_renovables.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_proteccion_al_consumidor.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_proteccion_de_funcionarios_y_exfuncionarios_riesgo_extraordinario.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_regulacion_actividades_y_profesiones_no_financieras_designadas.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_de_transito.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_transporte_terreste_de_honduras.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_programa_para_la_consolidacion_de_deudas_trabajador_hondureno.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_registro_nacional_de_las_personas.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_seguro_social.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_del_sistema_nacional_de_emergencia.id, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_electoral_y_de_las_organizaciones_politicas.id, tag_id: tag_decreto_legislativo.id})


LawTag.create({law_id: ley_especial_del_consejo_nacional_de_defensa, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_para_la_depuracion_policial, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_para_simplificacion_de_procedimientos_de_inversion_en_infraestructura_publica, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_reguladora_de_proyectos_publicos_de_energia_renovable, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_general_de_la_industria_electrica, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_marco_de_politicas_publicas_en_materia_social, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_recauca, tag_id: tag_tratado_internacional.id})
LawTag.create({law_id: ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_general_de_la_superintendencia_para_la_aplicacion_de_pruebas_de_evaluacion_de_confianza, tag_id:tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_de_intervencion_de_comunicaciones_privadas, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_para_el_ejercicio_del_sufragio_de_los_hondurenos_en_el_exterior, tag_id: tag_decreto_legislativo.id})
LawTag.create({law_id: ley_especial_que_regula_el_plesbicito_y_el_referendum, tag_id: tag_decreto_legislativo.id})

scrapped_laws_dir = '../ScrappedLaws/'

ARGV = [scrapped_laws_dir + 'Civil/ley_codigo_civil.json', ley_codigo_civil.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_codigo_del_comercio.json', ley_codigo_del_comercio.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Laboral/ley_codigo_del_trabajo.json', ley_codigo_del_trabajo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Penal/ley_codigo_penal.json', ley_codigo_penal.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Penal/ley_codigo_procesal_penal.json', ley_codigo_procesal_penal.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Constitucional/ley_constitucion_politica.json', ley_constitucion_politica.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Constitucional/ley_sobre_justicia.json', ley_sobre_justicia.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Ambiental/ley_forestal_areas_protegidas_y_vida_silvestre.json', ley_forestal_areas_protegidas_y_vida_silvestre.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Bancario/ley_de_creditos_usurarios.json', ley_de_creditos_usurarios.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Bancario/ley_de_instituciones_de_seguros_y_reaseguros.json', ley_de_instituciones_de_seguros_y_reaseguros.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Bancario/ley_del_banco_hondureño_del_cafe.json', ley_del_banco_hondureño_del_cafe.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_de_inversiones.json', ley_de_inversiones.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_de_propiedad_industrial.json', ley_de_propiedad_industrial.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Tributario/ley_del_impuesto_activo_neto.json', ley_del_impuesto_activo_neto.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_casas_de_cambio.json', ley_de_casas_de_cambio.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_contratacion_del_estado.json', ley_de_contratacion_del_estado.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.json', ley_de_control_de_armas_de_fuego_municiones_explosiones_y_otros_similares.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_creacion_de_fondo_de_apoyo_a_la_policia.json', ley_de_creacion_de_fondo_de_apoyo_a_la_policia.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.json', ley_de_facilitacion_administrativa_para_la_recontruccion_nacional.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_hidrocarburos.json', ley_de_hidrocarburos.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_procedimiento_administrativo.json', ley_de_procedimiento_administrativo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.json', ley_de_procedimiento_para_contratacion_de_financiamiento_y_consultoria_de_estudios_de_preinversion.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_simplificacion_administrativa.json', ley_de_simplificacion_administrativa.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.json', ley_de_transplante_y_extraccion_de_organos_y_tejidos_humanos.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_del_fondo_hondureno_de_preinversion.json', ley_del_fondo_hondureno_de_preinversion.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Familia/ley_codigo_de_familia.json', ley_codigo_de_familia.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_la_jurisdiccion_de_lo_contencioso_administrativo.json', ley_de_la_jurisdiccion_de_lo_contencioso_administrativo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_municipalidades.json', ley_de_municipalidades.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_propiedad.json', ley_de_propiedad.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_general_de_la_administracion_publica.json', ley_general_de_la_administracion_publica.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Judicial/ley_de_organizacion_y_atribucion_a_los_tribunales.json', ley_de_organizacion_y_atribucion_a_los_tribunales.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Tributario/ley_del_impuesto_sobre_renta.json', ley_del_impuesto_sobre_renta.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Civil/ley_codigo_procesal_civil.json', ley_codigo_procesal_civil.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Tributario/ley_del_impuesto_sobre_ventas.json', ley_del_impuesto_sobre_ventas.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_cauca.json', ley_cauca.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Tributario/ley_codigo_tributario.json', ley_codigo_tributario.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_constitutiva_de_la_empresa_nacional_de_energia_electrica.json', ley_constitutiva_de_la_empresa_nacional_de_energia_electrica.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_de_apoyo_a_la_micro_y_pequena_empresa.json', ley_de_apoyo_a_la_micro_y_pequena_empresa.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Penal/ley_de_creacion_del_consejo_nacional_contra_narcotrafico.json', ley_de_creacion_del_consejo_nacional_contra_narcotrafico.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_derecho_de_autor_y_derechos_conexos.json', ley_derecho_de_autor_y_derechos_conexos.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Penal/ley_de_disponibiilidad_emergente_de_activos_incautados.json', ley_de_disponibiilidad_emergente_de_activos_incautados.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_de_fomento_al_turismo.json', ley_de_fomento_al_turismo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_de_garantias_mobiliarias.json', ley_de_garantias_mobiliarias.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_inquilinato.json', ley_de_inquilinato.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_la_policia_militar_del_orden_publico.json', ley_de_la_policia_militar_del_orden_publico.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_zona_libre_turistica_islas_de_la_bahia.json', ley_zona_libre_turistica_islas_de_la_bahia.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_de_migracion_y_extranjeria.json', ley_de_migracion_y_extranjeria.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Mercantil/ley_proteccion_al_consumidor.json', ley_proteccion_al_consumidor.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_proteccion_de_funcionarios_y_exfuncionarios_riesgo_extraordinario.json', ley_proteccion_de_funcionarios_y_exfuncionarios_riesgo_extraordinario.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Bancario/ley_de_regulacion_actividades_y_profesiones_no_financieras_designadas.json', ley_de_regulacion_actividades_y_profesiones_no_financieras_designadas.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_de_transito.json', ley_de_transito.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_transporte_terreste_de_honduras.json', ley_transporte_terreste_de_honduras.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Laboral/ley_del_programa_para_la_consolidacion_de_deudas_trabajador_hondureno.json', ley_del_programa_para_la_consolidacion_de_deudas_trabajador_hondureno.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_del_registro_nacional_de_las_personas.json', ley_del_registro_nacional_de_las_personas.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_del_seguro_social.json', ley_del_seguro_social.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_del_sistema_nacional_de_emergencia.json', ley_del_sistema_nacional_de_emergencia.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Constitucional/ley_electoral_y_de_las_organizaciones_politicas.json', ley_electoral_y_de_las_organizaciones_politicas.id]
load scrapped_laws_dir + 'law_loader.rb'

ARGV = [scrapped_laws_dir + 'Administrativo/ley_especial_del_consejo_nacional_de_defensa.json', ley_especial_del_consejo_nacional_de_defensa.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_especial_para_la_depuracion_policial.json', ley_especial_para_la_depuracion_policial.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_especial_para_simplificacion_de_procedimientos_de_inversion_en_infraestructura_publica.json', ley_especial_para_simplificacion_de_procedimientos_de_inversion_en_infraestructura_publica.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_especial_reguladora_de_proyectos_publicos_de_energia_renovable.json', ley_especial_reguladora_de_proyectos_publicos_de_energia_renovable.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_general_de_la_industria_electrica.json', ley_general_de_la_industria_electrica.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_marco_de_politicas_publicas_en_materia_social.json', ley_marco_de_politicas_publicas_en_materia_social.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Administrativo/ley_recauca.json', ley_recauca.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo.json', ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Especiales_y_Otras/ley_general_de_la_superintendencia_para_la_aplicacion_de_pruebas_de_evaluacion_de_confianza.json', ley_especial_de_fomento_para_las_organizaciones_no_gubernamentales_de_desarrollo.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Penal/ley_especial_de_intervencion_de_comunicaciones_privadas.json', ley_especial_de_intervencion_de_comunicaciones_privadas.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Constitucional/ley_especial_para_el_ejercicio_del_sufragio_de_los_hondurenos_en_el_exterior.json', ley_especial_para_el_ejercicio_del_sufragio_de_los_hondurenos_en_el_exterior.id]
load scrapped_laws_dir + 'law_loader.rb'
ARGV = [scrapped_laws_dir + 'Constitucional/ley_especial_que_regula_el_plesbicito_y_el_referendum.json', ley_especial_que_regula_el_plesbicito_y_el_referendum.id]
load scrapped_laws_dir + 'law_loader.rb'
