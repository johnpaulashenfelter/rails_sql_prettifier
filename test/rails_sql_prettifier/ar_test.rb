require_relative '../test_helper'
require 'byebug'

ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Migration.create_table(:users)
ActiveRecord::Migration.create_table(:comments) do |t|
  t.belongs_to :user
end

class User < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
end

# ActiveRecord < 6 do not have connection_db_config method
# so it cannot be stubbed by usual Object stub method.
class << ActiveRecord::Base
  def stub_if_defined(name, val_or_callable, *block_args, &block)
    # stub only if respond otherwise just execute
    respond_to?( name ) ? stub(name, val_or_callable, *block_args, &block) : yield
  end
end

class ARTest < Minitest::Test
  extend ::ActiveSupport::Testing::Declarative

  test 'ar_using_pg_adapter? whenever AR is not defined will be false' do
    assert_equal( ActiveRecord::Base.connection_db_config.adapter, 'sqlite3' )
    assert( !Niceql::NiceQLConfig.new.ar_using_pg_adapter? )
  end

  test 'ar_using_pg_adapter? should be true whenever connection_db_config.adapter is postgresql' do
    ActiveRecord::Base.connection_db_config.stub(:adapter, 'postgresql') {
      assert(Niceql::NiceQLConfig.new.ar_using_pg_adapter?)
    }
  end

  test 'accessible through ActiveRecord and Arel' do
    User.create
    assert(!User.respond_to?(:to_niceql))                # ActiveRecord::Base
    assert(User.all.to_niceql.is_a?(String))             # ActiveRecord::Relation
    assert(User.last.comments.to_niceql.is_a?(String))   # ActiveRecord::Associations::CollectionProxy
    assert(User.all.arel.to_niceql.is_a?(String))        # Arel::TreeManager
    assert(User.all.arel.source.to_niceql.is_a?(String)) # Arel::Nodes::Node
  end
end
