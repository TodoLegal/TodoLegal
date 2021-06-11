# Tipo de acto retrieval
acuerdo_tag = Tag.find_by_name("Acuerdo")
decreto_tag = Tag.find_by_name("Decreto")
tratado_internacional_tag = Tag.find_by_name("Tratado Internacional")
resolucion_tag = Tag.find_by_name("Resolución")

# Tipo Instituciones retrieval
presidencia_tag = Tag.find_by_name("Presidencia")
congreso_nacional_tag = Tag.find_by_name("Congreso Nacional")
junta_militar_tag = Tag.find_by_name("Junta Militar")
asamblea_constituyente_tag = Tag.find_by_name("Asamblea Constituyente")
cnbs_tag = Tag.find_by_name("CNBS")
municipalidad_de_sps_tag = Tag.find_by_name("Municipalidad de SPS")

old_tag = Tag.find_by_name("Acuerdo Ejecutivo")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: acuerdo_tag)
  DocumentTag.create(document: document, tag: presidencia_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: acuerdo_tag)
  LawTag.create(law: law, tag: presidencia_tag)
end

old_tag = Tag.find_by_name("Decreto Ejecutivo")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: decreto_tag)
  DocumentTag.create(document: document, tag: presidencia_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: decreto_tag)
  LawTag.create(law: law, tag: presidencia_tag)
end

old_tag = Tag.find_by_name("Decreto Legislativo")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: decreto_tag)
  DocumentTag.create(document: document, tag: congreso_nacional_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: decreto_tag)
  LawTag.create(law: law, tag: congreso_nacional_tag)
end

old_tag = Tag.find_by_name("Decreto Junta Militar")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: decreto_tag)
  DocumentTag.create(document: document, tag: junta_militar_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: decreto_tag)
  LawTag.create(law: law, tag: junta_militar_tag)
end

old_tag = Tag.find_by_name("Tratado Internacional")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: decreto_tag)
  DocumentTag.create(document: document, tag: tratado_internacional_tag)
  DocumentTag.create(document: document, tag: congreso_nacional_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: decreto_tag)
  LawTag.create(law: law, tag: tratado_internacional_tag)
  LawTag.create(law: law, tag: congreso_nacional_tag)
end

old_tag = Tag.find_by_name("Asamblea Constituyente")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: decreto_tag)
  DocumentTag.create(document: document, tag: asamblea_constituyente_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: decreto_tag)
  LawTag.create(law: law, tag: asamblea_constituyente_tag)
end

old_tag = Tag.find_by_name("Resolución")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: resolucion_tag)
  DocumentTag.create(document: document, tag: cnbs_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: resolucion_tag)
  LawTag.create(law: law, tag: cnbs_tag)
end

old_tag = Tag.find_by_name("Acuerdo Ministerial")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: acuerdo_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: acuerdo_tag)
end

old_tag = Tag.find_by_name("Acto Municipal")
old_tag.documents.each do |document|
  DocumentTag.create(document: document, tag: acuerdo_tag)
  DocumentTag.create(document: document, tag: municipalidad_de_sps_tag)
end
old_tag.laws.each do |law|
  LawTag.create(law: law, tag: acuerdo_tag)
  LawTag.create(law: law, tag: municipalidad_de_sps_tag)
end