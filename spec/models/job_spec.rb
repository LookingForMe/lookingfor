require 'rails_helper'

describe Job do
  it "has a valid factory" do
    expect(build(:job)).to be_valid
  end

  before(:all) do
  Geocoder.configure(:lookup => :test)

  Geocoder::Lookup::Test.add_stub(
  "1510 Blake Street Denver CO", [
    {
      'latitude'     => 40.7143528,
      'longitude'    => -74.0059731,
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
     }
    ]
   )
  end

  let(:instance) { build(:job) }

  describe "Validations" do
    it { expect(instance).to validate_presence_of(:title) }
    it { expect(instance).to validate_uniqueness_of(:title) }
    it { expect(instance).to allow_value(['ruby', 'go']).for(:raw_technologies) }
  end

  it "can search by location case insensitive" do
    jobs = create_list(:job, 3)

    jobs[0].location.update_attributes(name: "DENVER")
    jobs[1].location.update_attributes(name: "DenveR")
    jobs[2].location.update_attributes(name: "Florida")

    results = Job.by_location("Denver")
    expect(results.count).to eq(2)
  end

  it "can search by location case partial match" do
    jobs = create_list(:job, 3)

    jobs[0].location.update_attributes(name: "DENVER, CO")
    jobs[1].location.update_attributes(name: "DENVER, COLORADO")
    jobs[2].location.update_attributes(name: "Denver is the kewlest place ever")
    
    results = Job.by_location("Denver")
    expect(results.count).to eq(3)
  end

  describe "Associations" do
    it { expect(instance).to belong_to(:company) }
    it { expect(instance).to belong_to(:location) }
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

  describe 'geocodes' do
    it 'uses geocoder to fetch lat and long coordinates' do
      job = Job.create(old_location: "1510 Blake Street Denver CO")
      coords = Geocoder.search(job.old_location).first.data

      expect(coords['latitude']).to eq(40.7143528)
      expect(coords['longitude']).to eq(-74.0059731)
    end
  end

  describe '#total_pages' do
    it 'returns the total amount of pages' do
      create_list(:job, 30)
      tech = create(:technology, name: "ruby")
      Job.find_each {|job| job.technologies << tech}

      expect(Job.count).to eq(30)
      expect(Job.total_pages(4)).to eq(8)
    end
  end
end
