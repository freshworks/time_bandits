module DalliDuplicateCounter
  include CustomRequestStore

  def self.key_already_exists?(key, operation)
    counter = get_counter(operation)
    if counter[key].present?
      return true
    else
     counter.store(key,1)
      return false
    end
  end

  
  private
  def get_counter(operation)
    if "read".eql? operation
      return CustomRequestStore.store[:duplicate_read_counter] ||
          CustomRequestStore.store[:duplicate_read_counter] = {}
    elsif "write".eql? operation
      return CustomRequestStore.store[:duplicate_write_counter] ||
          CustomRequestStore.store[:duplicate_write_counter] = {}
    elsif "delete".eql? operation
      return CustomRequestStore.store[:duplicate_delete_counter] ||
          CustomRequestStore.store[:duplicate_delete_counter] = {}
    end
  end
end