require 'rails_helper'

describe Job do
  it "has a valid factory" do
    expect(build(:job)).to be_valid
  end

  let(:instance) { build(:job) }

  describe "Validations" do
    it { expect(instance).to validate_presence_of(:title) }
    it { expect(instance).to validate_uniqueness_of(:title) }
    it { expect(instance).to allow_value(['ruby', 'go']).for(:raw_technologies) }
  end

  it "can search by location case insensitive" do
    two_month_job = create(:job)
    two_month_job.update(location: "DENVER")
    one_month_job = create(:job)
    one_month_job.update(location: "DENVER")
    current_job = create(:job)
    current_job.update(location: "Florida")
    results = Job.by_location("Denver")
    expect(results.count).to eq(2)
  end

  it "can search by location case partial match" do
    two_month_job = create(:job)
    two_month_job.update(location: "DENVER, CO")
    one_month_job = create(:job)
    one_month_job.update(location: "DENVER, COLORADO")
    current_job = create(:job)
    current_job.update(location: "Denver is the coolest place ever")
    results = Job.by_location("Denver")
    expect(results.count).to eq(3)
  end

  describe "Associations" do
    it { expect(instance).to belong_to(:company) }
    it { expect(instance).to have_and_belong_to_many(:technologies) }
  end

  describe "Callbacks" do
    it 'downcases raw_technologies' do
      object = create(:job, raw_technologies: ['Ruby', 'Go'])
      expect(object.raw_technologies).to match(['ruby', 'go'])
    end
  end

  describe '#assign_tech' do
    it 'assignes any technologies that match raw tech' do
      existing_tech = create(:technology, name: 'ruby')
      object = create(:job, raw_technologies: ['ruby', 'java'])
      object.assign_tech
      expect(Job.last.technologies.count).to eq(1)
      expect(Job.last.technologies.first).to eq(existing_tech)
    end

    context 'when no matches exist' do
      it 'assigns no technologies' do
        existing_tech = create(:technology, name: 'ruby')
        object = create(:job, raw_technologies: ['java'])
        object.assign_tech
        expect(object.technologies.count).to eq(0)
      end
    end
  end
end
