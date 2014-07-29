require 'event_sorcerer'

describe EventSorcerer do
  describe '.with_unit_of_work' do
    it 'puts a new unit of work in the thread variables' do
      EventSorcerer.with_unit_of_work do
        expect(Thread.current[:unit_of_work]).to be_truthy
      end
    end
  end
end
