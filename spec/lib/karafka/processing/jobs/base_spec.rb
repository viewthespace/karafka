# frozen_string_literal: true

RSpec.describe_current do
  subject(:job) { described_class.new }

  describe '#non_blocking?' do
    it 'expect all the newly created jobs to be blocking' do
      expect(job.non_blocking?).to eq(false)
    end
  end

  describe '#call' do
    it { expect { job.call }.to raise_error(NotImplementedError) }
  end

  describe '#finished? and #finish!' do
    it { expect(job.finished?).to eq(false) }

    context 'when job is finished' do
      before { job.finish! }

      it { expect(job.finished?).to eq(true) }
    end
  end
end
