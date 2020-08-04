# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::EmptyLines do
  subject(:cop) { described_class.new }

  it 'registers an offense for consecutive empty lines' do
    expect_offense(<<~RUBY)
      test = 5


      ^{} Extra blank line detected.
      top
    RUBY

    expect_correction(<<~RUBY)
      test = 5

      top
    RUBY
  end

  it 'works when there are no tokens' do
    expect_no_offenses('#comment')
  end

  it 'handles comments' do
    expect_no_offenses(<<~RUBY)
      test

      #comment
      top
    RUBY
  end

  it 'does not register an offense for empty lines in a string' do
    expect_no_offenses(<<~RUBY)
      result = "test



                                        string"
    RUBY
  end

  it 'does not register an offense for heredocs with empty lines inside' do
    expect_no_offenses(<<~RUBY)
      str = <<-TEXT
      line 1


      line 2
      TEXT
      puts str
    RUBY
  end
end
