# frozen_string_literal: true

require "rails_helper"

RSpec.describe RubygemUpdateJob, type: :job do
  let(:job) { described_class.new }
  let(:do_perform) { job.perform gem_name }
  let(:gem_name) { "rspec" }

  describe "#perform" do
    let(:expected_attributes) do
      {
        authors:                    "Steven Baker, David Chelimsky, Myron Marston",
        bug_tracker_url:            nil,
        current_version:            "3.7.0",
        documentation_url:          "http://relishapp.com/rspec",
        downloads:                  145_999_055,
        homepage_url:               "http://github.com/rspec",
        licenses:                   %w[MIT],
        mailing_list_url:           "http://rubyforge.org/mailman/listinfo/rspec-users",
        name:                       "rspec",
        source_code_url:            "http://github.com/rspec/rspec",
        wiki_url:                   nil,
        first_release_on:           Date.new(2005, 8, 11),
        latest_release_on:          Date.new(2017, 10, 17),
        releases_count:             3,
        reverse_dependencies_count: 6,
      }
    end

    it "applies the remote info attributes" do
      do_perform

      expect(Rubygem.find(gem_name)).to have_attributes(expected_attributes)
    end

    it "changes the updated_at timestamp regardless of changes" do
      described_class.new.perform gem_name
      Rubygem.find(gem_name).update! updated_at: 2.days.ago
      expect { do_perform }.to(change { Rubygem.find(gem_name).updated_at })
    end

    it "enqueues a corresponding project update job" do
      expect(ProjectUpdateJob).to receive(:perform_async).with(gem_name)
      do_perform
    end

    describe "when rubygems.org is down" do
      let(:gem_name) { "thisisdowninmock" }

      it "raises an exception" do
        expect { do_perform }.to raise_error "Unknown response status 500"
      end
    end
  end
end
