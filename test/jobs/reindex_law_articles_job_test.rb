require 'test_helper'

class ReindexLawArticlesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "job reindexes articles for Constitución" do
    law = laws(:one)
    assert_nothing_raised do
      ReindexLawArticlesJob.perform_now(law.id)
    end
  end

  test "job handles nonexistent law gracefully" do
    assert_nothing_raised do
      ReindexLawArticlesJob.perform_now(-1)
    end
  end

  test "updating Constitución name enqueues reindex job" do
    law = laws(:one)
    assert_enqueued_with(job: ReindexLawArticlesJob, args: [law.id]) do
      law.update(name: "Constitución de la República (Reformada)")
    end
  end

  test "updating Código Penal status enqueues reindex job" do
    law = laws(:two)
    assert_enqueued_with(job: ReindexLawArticlesJob, args: [law.id]) do
      law.update(status: "derogado")
    end
  end
end
