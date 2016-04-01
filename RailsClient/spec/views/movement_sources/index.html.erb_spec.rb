require 'rails_helper'

RSpec.describe "movement_sources/index", type: :view do
  before(:each) do
    assign(:movement_sources, [
      MovementSource.create!(
        :movement_list_id => "Movement List",
        :fromWh => "From Wh",
        :fromPosition => "From Position",
        :packageId => "Package",
        :partNr => "Part Nr",
        :qty => "Qty",
        :fifo => "Fifo",
        :toWh => "To Wh",
        :toPosition => "To Position",
        :employee_id => "Employee",
        :remarks => "Remarks"
      ),
      MovementSource.create!(
        :movement_list_id => "Movement List",
        :fromWh => "From Wh",
        :fromPosition => "From Position",
        :packageId => "Package",
        :partNr => "Part Nr",
        :qty => "Qty",
        :fifo => "Fifo",
        :toWh => "To Wh",
        :toPosition => "To Position",
        :employee_id => "Employee",
        :remarks => "Remarks"
      )
    ])
  end

  it "renders a list of movement_sources" do
    render
    assert_select "tr>td", :text => "Movement List".to_s, :count => 2
    assert_select "tr>td", :text => "From Wh".to_s, :count => 2
    assert_select "tr>td", :text => "From Position".to_s, :count => 2
    assert_select "tr>td", :text => "Package".to_s, :count => 2
    assert_select "tr>td", :text => "Part Nr".to_s, :count => 2
    assert_select "tr>td", :text => "Qty".to_s, :count => 2
    assert_select "tr>td", :text => "Fifo".to_s, :count => 2
    assert_select "tr>td", :text => "To Wh".to_s, :count => 2
    assert_select "tr>td", :text => "To Position".to_s, :count => 2
    assert_select "tr>td", :text => "Employee".to_s, :count => 2
    assert_select "tr>td", :text => "Remarks".to_s, :count => 2
  end
end
