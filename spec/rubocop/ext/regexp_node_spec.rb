# frozen_string_literal: true

require 'timeout'

RSpec.describe RuboCop::Ext::RegexpNode do
  let(:source) { '/(hello)(?<foo>world)(?:not captured)/' }
  let(:processed_source) { parse_source(source) }
  let(:ast) { processed_source.ast }
  let(:node) { ast }

  describe '#each_capture' do
    subject(:captures) { node.each_capture(**arg).to_a }

    let(:named) { be_instance_of(Regexp::Expression::Group::Named) }
    let(:positional) { be_instance_of(Regexp::Expression::Group::Capture) }

    context 'when called without argument' do
      let(:arg) { {} }

      it { is_expected.to match [positional, named] }
    end

    context 'when called with a `named: false`' do
      let(:arg) { { named: false } }

      it { is_expected.to match [positional] }
    end

    context 'when called with a `named: true`' do
      let(:arg) { { named: true } }

      it { is_expected.to match [named] }
    end
  end

  describe '#parsed_tree' do
    let(:source) { '/foo#{bar}baz/' }

    context 'with an extended mode regexp with comment' do
      let(:source) { '/42 # the answer/x' }

      it 'returns the expected tree' do
        tree = node.parsed_tree

        expect(tree.is_a?(Regexp::Expression::Root)).to eq(true)
        expect(tree.map(&:token)).to eq(%i[literal whitespace comment])
      end
    end

    context 'with a regexp containing interpolation' do
      it 'returns the expected blanked tree' do
        tree = node.parsed_tree

        expect(tree.is_a?(Regexp::Expression::Root)).to eq(true)
        expect(tree.to_s).to eq('foo      baz')
      end
    end

    context 'with a regexp containing a multi-line interpolation' do
      let(:source) do
        <<~'REGEXP'
          /
            foo
            #{
              bar(
                42
              )
            }
            baz
          /
        REGEXP
      end

      it 'returns the expected blanked tree' do
        tree = node.parsed_tree

        expect(tree.is_a?(Regexp::Expression::Root)).to eq(true)
        expect(tree.to_s.split("\n")).to eq(
          [
            '',
            '  foo',
            ' ' * 32,
            '  baz'
          ]
        )
      end
    end

    context 'with a regexp not containing interpolation' do
      let(:source) { '/foobaz/' }

      it 'returns the expected tree' do
        tree = node.parsed_tree

        expect(tree.is_a?(Regexp::Expression::Root)).to eq(true)
        expect(tree.to_s).to eq('foobaz')
      end
    end
  end

  describe '#parsed_node_loc' do
    let(:source) { '/([a-z]+)\d*\s?(?:foo)/' }

    it 'returns the correct loc for each node in the parsed_tree' do
      loc_sources = node.parsed_tree.each_expression.map do |regexp_node|
        node.parsed_tree_expr_loc(regexp_node).source
      end

      expect(loc_sources).to eq(
        [
          '([a-z]+)',
          '[a-z]+',
          'a-z',
          'a',
          'z',
          '\d*',
          '\s?',
          '(?:foo)',
          'foo'
        ]
      )
    end
  end
end
