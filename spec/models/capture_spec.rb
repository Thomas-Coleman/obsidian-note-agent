require 'rails_helper'

RSpec.describe Capture, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it do
      should define_enum_for(:status)
        .with_values(
          pending: 0,
          processing: 1,
          summarizing: 2,
          enriching: 3,
          formatting: 4,
          published: 5,
          failed: 6
        )
        .with_prefix(:status)
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:old_capture) { create(:capture, user: user, created_at: 3.days.ago) }
    let!(:new_capture) { create(:capture, user: user, created_at: 2.days.ago) }
    let!(:pending_capture) { create(:capture, :pending, user: user, created_at: 1.day.ago) }
    let!(:published_capture) { create(:capture, :published, user: user, created_at: Time.current) }

    describe '.recent' do
      it 'orders captures by created_at descending' do
        expect(Capture.recent.pluck(:id)).to eq([ published_capture.id, pending_capture.id, new_capture.id, old_capture.id ])
      end
    end

    describe '.by_status' do
      it 'filters by status when provided' do
        expect(Capture.by_status(:published)).to contain_exactly(published_capture)
        expect(Capture.by_status(:pending)).to contain_exactly(pending_capture, old_capture, new_capture)
      end

      it 'returns all when status is blank' do
        expect(Capture.by_status(nil).count).to eq(4)
        expect(Capture.by_status('').count).to eq(4)
      end
    end
  end

  describe 'default values' do
    it 'sets default tags to empty array' do
      capture = Capture.new
      expect(capture.tags).to eq([])
    end

    it 'sets default metadata to empty hash' do
      capture = Capture.new
      expect(capture.metadata).to eq({})
    end

    it 'sets default obsidian_folder to Captures' do
      capture = Capture.new
      expect(capture.obsidian_folder).to eq('Captures')
    end
  end

  describe '#successful?' do
    it 'returns true when status is published' do
      capture = create(:capture, :published)
      expect(capture.successful?).to be true
    end

    it 'returns false for other statuses' do
      capture = create(:capture, :pending)
      expect(capture.successful?).to be false
    end
  end

  describe '#processing?' do
    it 'returns true for processing statuses' do
      %i[processing summarizing enriching formatting].each do |status|
        capture = create(:capture, status: status)
        expect(capture.processing?).to be true
      end
    end

    it 'returns false for non-processing statuses' do
      %i[pending published failed].each do |status|
        capture = create(:capture, status: status)
        expect(capture.processing?).to be false
      end
    end
  end

  describe 'status transitions' do
    let(:capture) { create(:capture, :pending) }

    it 'can transition through the pipeline' do
      expect(capture.status_pending?).to be true

      capture.status_processing!
      expect(capture.status_processing?).to be true

      capture.status_summarizing!
      expect(capture.status_summarizing?).to be true

      capture.status_enriching!
      expect(capture.status_enriching?).to be true

      capture.status_formatting!
      expect(capture.status_formatting?).to be true

      capture.status_published!
      expect(capture.status_published?).to be true
    end

    it 'can transition to failed from any status' do
      capture.status_processing!
      capture.status_failed!
      expect(capture.status_failed?).to be true
    end
  end
end
