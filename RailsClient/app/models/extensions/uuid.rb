module Extensions
  module UUID
    extend ActiveSupport::Concern
    included do
      #set_primary_key 'id' rails 3
      #self.primary_key='id' # rails 4
      default_scope { where(is_delete: false) }
      validates_uniqueness_of :id
      after_initialize :generate_uuid
      before_create :set_timestamps
      before_update :reset_dirty_flag

      def generate_uuid
        self.id = self.send(:generate_id) if self.id.nil? && self.respond_to?(:generate_id)
        self.id = SecureRandom.uuid if self.id.nil?
        self.uuid= SecureRandom.uuid if self.respond_to?(:uuid) and self.send(:uuid).nil?
      end

      def set_timestamps
        self.created_at = Time.now if self.created_at.nil?
        self.updated_at = Time.now if self.updated_at.nil?
      end

      def reset_dirty_flag
        if !self.is_dirty_changed? and self.changes.count>0
          self.is_dirty=true
        end
      end

      def self.skip_callbacks
        self.skip_callback(:update, :before, :reset_dirty_flag)
      end

      def self.reset_callbacks
        self.set_callback(:update, :before, :reset_dirty_flag)
        if self.methods.include? :tricky_reset
          self.tricky_reset
        end
      end

      def destroy
        # self.send(:destroy_dependent, self.id) if self.respond_to?(:destroy_dependent)
        self.is_delete=true
        self.is_dirty=true
        self.save
      end

      def update_info
        if self.is_dirty
          '未同步'
        else
          '已同步'
        end
      end

      # for sync
      def self.fk_condition(arg)
        c={}
        self::FK.each do |k|
          c[k]=arg[k]
        end
        return c
      end

      def gen_sync_attr(item)
        attr={}
        self.attributes.except('uuid', 'is_dirty', 'is_new').keys.each do |k|
          attr[k.to_sym]=item.send(k.to_sym)
        end
        return attr
      end

      def gen_uniq_sync_attr(item)
        attr={}
        self.attributes.except('id', 'is_dirty', 'is_new').keys.each do |k|
          attr[k.to_sym]=item.send(k.to_sym)
        end
        return attr
      end

      def can_reset_sync_dirty_flag
        true
      end
    end
  end
end
