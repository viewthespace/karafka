# frozen_string_literal: true

RSpec.describe_current do
  let(:combination) do
    %i[
      active_job
      manual_offset_management
      throttling
    ]
  end

  it { expect(described_class::FEATURES).to eq(combination) }
end
