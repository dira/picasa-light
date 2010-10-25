require File.dirname(__FILE__) + '/../test_helper'

describe 'Photo manipulation' do
  [
    [[1000, 500, 100], [100, 50]],
    [[500, 1000, 100], [50, 100]],
    [[50, 100, 1000],  [50, 100]],
    [[150, 100, 1000], [150, 100]]
  ].each do |photo, result|
    it "computes the size for a #{photo[0]}x#{photo[1]} photo, max #{photo[2]} as #{result[0]}x#{result[1]}" do
      PicasaAPI::photo_size({ :width => photo[0], :height => photo[1]}, photo[2]).should.equal({ :width => result[0], :height => result[1]})
    end
  end
end
