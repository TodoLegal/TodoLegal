# frozen_string_literal: true

class AddNewDatapointTypesAndAdjustPriorities < ActiveRecord::Migration[7.1]
  def up
    ActiveRecord::Base.transaction do
      # Step 1: Adjust existing priorities to make room for Amends(4) and Repeals(5)
      adjust_existing_priorities
      
      # Step 2: Create new datapoint types
      create_new_datapoint_types
    end
  end

  def down
    ActiveRecord::Base.transaction do
      # Remove new datapoint types
      DatapointType.where(name: ['Publication Date', 'Amends', 'Repeals']).destroy_all
      
      # Restore original priorities
      restore_original_priorities
    end
  end

  private

  def adjust_existing_priorities
    # Shift existing priorities to make room for Amends(4) and Repeals(5)
    # All priorities 4 and above move up by 2 positions
    
    Rails.logger.info "Adjusting existing datapoint type priorities..."
    
    # Shift in reverse order to avoid conflicts
    DatapointType.where(name: 'Name').update_all(priority: 10)           # 8 → 10
    DatapointType.where(name: 'Tipo de Acto').update_all(priority: 9)    # 7 → 9  
    DatapointType.where(name: 'Materia').update_all(priority: 8)         # 6 → 8
    DatapointType.where(name: 'Tema').update_all(priority: 7)            # 5 → 7
    DatapointType.where(name: 'Issuer').update_all(priority: 6)          # 4 → 6
    
    Rails.logger.info "Priority adjustments completed"
  end

  def create_new_datapoint_types
    Rails.logger.info "Creating new datapoint types..."
    
    new_types = [
      {
        name: 'Amends',
        priority: 4,
        difficulty: 2,
        description: 'Señala qué documento previo está siendo modificado por el texto actual. Permite rastrear los cambios que se han hecho a un documento anterior.'
      },
      {
        name: 'Repeals',
        priority: 5,
        difficulty: 2,
        description: 'Indica qué documento queda sin efecto a partir de la publicación del nuevo texto. Con ello se aclara qué documentos anteriores dejan de estar vigentes.'
      },
      {
        name: 'Publication Date',
        priority: 11,
        difficulty: 1,
        description: 'Es la fecha oficial en la que el documento fue publicado por la institución emisora. Esta fecha marca el inicio de su vigencia, salvo que el propio documento indique otra disposición.'
      }
    ]
    
    DatapointType.create!(new_types)
    
    Rails.logger.info "New datapoint types created successfully"
  end

  def restore_original_priorities
    Rails.logger.info "Restoring original datapoint type priorities..."
    
    # Restore original priorities if rolling back
    DatapointType.where(name: 'Issuer').update_all(priority: 4)
    DatapointType.where(name: 'Tema').update_all(priority: 5)
    DatapointType.where(name: 'Materia').update_all(priority: 6)
    DatapointType.where(name: 'Tipo de Acto').update_all(priority: 7)
    DatapointType.where(name: 'Name').update_all(priority: 8)
    
    Rails.logger.info "Original priorities restored"
  end
end
