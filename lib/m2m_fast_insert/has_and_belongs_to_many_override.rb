module M2MFastInsert
  module HasAndBelongsToManyOverride
    extend ActiveSupport::Concern
    included do
      class_eval do
        # Create Method chain if habtm is defined - This is because it goes down to AR::Base
        # and errors because at the time of inclusion, there is none defined
        if self.method_defined? :build
          alias_method_chain :build, :fast_inserts
        else
          raise "wtf"
        end
      end
    end

    # Rig the original habtm to call our method definition
    #
    # name - Plural name of the model we're associating with
    # options - see ActiveRecord docs
    def build_with_fast_inserts
      build_without_fast_inserts
      define_fast_methods_for_model(name, options)
    end

    private
    # Get necessary table and column information so we can define
    # fast insertion methods
    #
    # name - Plural name of the model we're associating with
    # options - see ActiveRecord docs
    def define_fast_methods_for_model(name, options)
      join_table = options[:join_table]
      join_column_name = name.to_s.downcase.singularize
      model.send(:include, Module.new {
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def fast_#{join_column_name}_ids_insert(*args)
            table_name = self.class.table_name.singularize
            insert = M2MFastInsert::Base.new id, #{join_column_name}, table_name, #{join_table}, *args
            insert.fast_insert
          end
        RUBY
      })
    end
  end
end
ActiveRecord::Associations::Builder::HasAndBelongsToMany.send :include, M2MFastInsert::HasAndBelongsToManyOverride
