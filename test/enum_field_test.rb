$LOAD_PATH.reject! { |path| path.include?('TextMate') }
require 'test/unit'
require 'rubygems'
require 'active_support'
require 'mocha'
require 'shoulda'
require 'active_record'
require File.dirname(__FILE__)+'/../lib/enum_field'
require File.dirname(__FILE__)+'/../init'

class MockedModel; include EnumField; end;

class EnumFieldTest < Test::Unit::TestCase
  context "with a simple gender enum" do
    setup do
      @possible_values = %w( male female )

      MockedModel.expects(:named_scope).with(:male, :conditions => {:gender => "male"})
      MockedModel.expects(:named_scope).with(:female, :conditions => {:gender => "female"})
      MockedModel.expects(:validates_inclusion_of).with(:gender, :in => @possible_values, :message => "invalid gender")
      MockedModel.send(:enum_field, :gender, @possible_values)
    end
  
    should "create constant with possible values named as pluralized field" do
      assert_equal @possible_values, MockedModel::GENDERS
    end
    
    should "freeze the constant to prevent modifications" do
      assert_raise TypeError do
        MockedModel::GENDERS << "not a man, not a woman"
      end
    end
    
    should "create query methods for each enum type" do
      model = MockedModel.new
      
      model.stubs(:gender).returns("male")
      assert model.male?
      assert !model.female?
      model.stubs(:gender).returns("female")
      assert !model.male?
      assert model.female?
    end
    
    should "add named scopes for each enum type" do
      # MockedModel.expects(:named_scope).with(:male, :conditions => {:gender => :male})
    end
    
    should "extend active record base with method" do
      assert_respond_to ActiveRecord::Base, :enum_field
    end
    
  end

  context "Specifying a message" do
    setup do
      @possible_values = %w(on off)
      MockedModel.stubs(:named_scope)
      MockedModel.expects(:validates_inclusion_of).with(:status, :in => @possible_values, :message => "custom insult")
    end

    should "override the default message" do
      MockedModel.send(:enum_field, :status, @possible_values, :message => 'custom insult')
    end
  end

  context "With an enum containing multiple word choices" do
    setup do
      MockedModel.stubs(:validates_inclusion_of)
      MockedModel.stubs(:named_scope)
      MockedModel.send :enum_field, :field, ['choice one', 'choice-two', 'other']
      @model = MockedModel.new
    end

    should "define an underscored query method for the multiple word choice" do
      assert_respond_to @model, :choice_one?
    end

    should "define an underscored query method for the dasherized choice" do
      assert_respond_to @model, :choice_two?
    end
  end

  context "With an enum containing mixed case choices" do
    setup do
      MockedModel.stubs(:validates_inclusion_of)
      MockedModel.stubs(:named_scope)
      MockedModel.send :enum_field, :field, ['Choice One', 'ChoiceTwo', 'Other']
      @model = MockedModel.new
    end

    should "define a lowercase, underscored query method for the multiple word choice" do
      assert_respond_to @model, :choice_one?
    end

    should "define a lowercase query method for the camelcase choice" do
      assert_respond_to @model, :choicetwo?
    end
  end

  context "With an enum containing strange characters" do
    setup do
      MockedModel.stubs(:validates_inclusion_of)
      MockedModel.stubs(:named_scope)
      MockedModel.send :enum_field, :field, ['choice%one', 'choice☺two', 'other.']
      @model = MockedModel.new
    end

    should "define a normal query method for the unicode choice" do
      assert_respond_to @model, :choice_two?
    end

    should "define a normal query method for the % choice" do
      assert_respond_to @model, :choice_one?
    end

    should "define a query method without the trailing punctuation for the other choice" do
      assert_respond_to @model, :other?
    end
  end
  
  context "With the prefix option" do
    setup do
      @possible_values = %w(on off)
      MockedModel.expects(:validates_inclusion_of)
      MockedModel.stubs(:named_scope)
      MockedModel.send(:enum_field, :status, @possible_values, :prefix => true)
    end
    
    should "create query methods prefixed with the field name" do
      model = MockedModel.new
      
      model.stubs(:status).returns("on")
      assert model.status_on?
      assert !model.status_off?
    end
  end
  
end

