RSpec.describe Magick::ImageList do
  before do
    @list = Magick::ImageList.new(*FILES[0..9])
    @list2 = Magick::ImageList.new # intersection is 5..9
    @list2 << @list[5]
    @list2 << @list[6]
    @list2 << @list[7]
    @list2 << @list[8]
    @list2 << @list[9]
  end

  describe '#combine' do
    it 'works' do
      red   = Magick::Image.new(20, 20) { self.background_color = 'red' }
      green = Magick::Image.new(20, 20) { self.background_color = 'green' }
      blue  = Magick::Image.new(20, 20) { self.background_color = 'blue' }
      black = Magick::Image.new(20, 20) { self.background_color = 'black' }
      alpha = Magick::Image.new(20, 20) { self.background_color = 'transparent' }

      list = Magick::ImageList.new
      expect { list.combine }.to raise_error(ArgumentError)

      list << red
      expect { list.combine }.not_to raise_error

      res = list.combine
      expect(res).to be_instance_of(Magick::Image)

      list << alpha
      expect { list.combine }.not_to raise_error

      list.pop
      list << green
      list << blue
      expect { list.combine }.not_to raise_error

      list << alpha
      expect { list.combine }.not_to raise_error

      list.pop
      list << black
      expect { list.combine(Magick::CMYKColorspace) }.not_to raise_error
      expect { list.combine(Magick::SRGBColorspace) }.not_to raise_error

      list << alpha
      expect { list.combine(Magick::CMYKColorspace) }.not_to raise_error
      expect { list.combine(Magick::SRGBColorspace) }.to raise_error(ArgumentError)

      list << alpha
      expect { list.combine }.to raise_error(ArgumentError)

      expect { list.combine(nil) }.to raise_error(TypeError)
      expect { list.combine(Magick::SRGBColorspace, 1) }.to raise_error(ArgumentError)
    end
  end

  describe '#composite_layers' do
    it 'works' do
      expect { @list.composite_layers(@list2) }.not_to raise_error
      Magick::CompositeOperator.values do |op|
        expect { @list.composite_layers(@list2, op) }.not_to raise_error
      end

      expect { @list.composite_layers(@list2, Magick::ModulusAddCompositeOp, 42) }.to raise_error(ArgumentError)
    end
  end

  describe '#delay' do
    it 'works' do
      expect { @list.delay }.not_to raise_error
      expect(@list.delay).to eq(0)
      expect { @list.delay = 20 }.not_to raise_error
      expect(@list.delay).to eq(20)
      expect { @list.delay = 'x' }.to raise_error(ArgumentError)
    end
  end

  describe '#flatten_images' do
    it 'works' do
      expect { @list.flatten_images }.not_to raise_error
    end
  end

  describe '#ticks_per_second' do
    it 'works' do
      expect { @list.ticks_per_second }.not_to raise_error
      expect(@list.ticks_per_second).to eq(100)
      expect { @list.ticks_per_second = 1000 }.not_to raise_error
      expect(@list.ticks_per_second).to eq(1000)
      expect { @list.ticks_per_second = 'x' }.to raise_error(ArgumentError)
    end
  end

  describe '#iterations' do
    it 'works' do
      expect { @list.iterations }.not_to raise_error
      expect(@list.iterations).to be_kind_of(Integer)
      expect { @list.iterations = 20 }.not_to raise_error
      expect(@list.iterations).to eq(20)
      expect { @list.iterations = 'x' }.to raise_error(ArgumentError)
    end
  end

  # also tests #size
  describe '#length' do
    it 'works' do
      expect { @list.length }.not_to raise_error
      expect(@list.length).to eq(10)
      expect { @list.length = 2 }.to raise_error(NoMethodError)
    end
  end

  describe '#scene' do
    it 'works' do
      expect { @list.scene }.not_to raise_error
      expect(@list.scene).to eq(9)
      expect { @list.scene = 0 }.not_to raise_error
      expect(@list.scene).to eq(0)
      expect { @list.scene = 1 }.not_to raise_error
      expect(@list.scene).to eq(1)
      expect { @list.scene = -1 }.to raise_error(IndexError)
      expect { @list.scene = 1000 }.to raise_error(IndexError)
      expect { @list.scene = nil }.to raise_error(IndexError)

      # allow nil on empty list
      empty_list = Magick::ImageList.new
      expect { empty_list.scene = nil }.not_to raise_error
    end
  end

  describe '#undef_array_methods' do
    it 'works' do
      expect { @list.assoc }.to raise_error(NoMethodError)
      expect { @list.flatten }.to raise_error(NoMethodError)
      expect { @list.flatten! }.to raise_error(NoMethodError)
      expect { @list.join }.to raise_error(NoMethodError)
      expect { @list.pack }.to raise_error(NoMethodError)
      expect { @list.rassoc }.to raise_error(NoMethodError)
    end
  end

  describe '#all' do
    it 'works' do
      q = nil
      expect { q = @list.all? { |i| i.class == Magick::Image } }.not_to raise_error
      expect(q).to be(true)
    end
  end

  describe '#any' do
    it 'works' do
      q = nil
      expect { q = @list.all? { |_i| false } }.not_to raise_error
      expect(q).to be(false)
      expect { q = @list.all? { |i| i.class == Magick::Image } }.not_to raise_error
      expect(q).to be(true)
    end
  end

  describe '#aref' do
    it 'works' do
      expect { @list[0] }.not_to raise_error
      expect(@list[0]).to be_instance_of(Magick::Image)
      expect(@list[-1]).to be_instance_of(Magick::Image)
      expect(@list[0, 1]).to be_instance_of(Magick::ImageList)
      expect(@list[0..2]).to be_instance_of(Magick::ImageList)
      expect(@list[20]).to be(nil)
    end
  end

  describe '#aset' do
    it 'works' do
      img = Magick::Image.new(5, 5)
      expect do
        rv = @list[0] = img
        expect(rv).to be(img)
        expect(@list[0]).to be(img)
        expect(@list.scene).to eq(0)
      end.not_to raise_error

      # replace 2 images with 1
      expect do
        img = Magick::Image.new(5, 5)
        rv = @list[1, 2] = img
        expect(rv).to be(img)
        expect(@list.length).to eq(9)
        expect(@list[1]).to be(img)
        expect(@list.scene).to eq(1)
      end.not_to raise_error

      # replace 1 image with 2
      expect do
        img = Magick::Image.new(5, 5)
        img2 = Magick::Image.new(5, 5)
        ary = [img, img2]
        rv = @list[3, 1] = ary
        expect(rv).to be(ary)
        expect(@list.length).to eq(10)
        expect(@list[3]).to be(img)
        expect(@list[4]).to be(img2)
        expect(@list.scene).to eq(4)
      end.not_to raise_error

      expect do
        img = Magick::Image.new(5, 5)
        rv = @list[5..6] = img
        expect(rv).to be(img)
        expect(@list.length).to eq(9)
        expect(@list[5]).to be(img)
        expect(@list.scene).to eq(5)
      end.not_to raise_error

      expect do
        ary = [img, img]
        rv = @list[7..8] = ary
        expect(rv).to be(ary)
        expect(@list.length).to eq(9)
        expect(@list[7]).to be(img)
        expect(@list[8]).to be(img)
        expect(@list.scene).to eq(8)
      end.not_to raise_error

      expect do
        rv = @list[-1] = img
        expect(rv).to be(img)
        expect(@list.length).to eq(9)
        expect(@list[8]).to be(img)
        expect(@list.scene).to eq(8)
      end.not_to raise_error

      expect { @list[0] = 1 }.to raise_error(ArgumentError)
      expect { @list[0, 1] = [1, 2] }.to raise_error(ArgumentError)
      expect { @list[2..3] = 'x' }.to raise_error(ArgumentError)
    end
  end

  describe '#and' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect do
        res = @list & @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(@list).not_to be(res)
        expect(@list2).not_to be(res)
        expect(res.length).to eq(5)
        expect(res.scene).to eq(2)
        expect(res.cur_image).to be(cur)
      end.not_to raise_error

      # current scene not in the result, set result scene to last image in result
      @list.scene = 2
      expect do
        res = @list & @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.scene).to eq(4)
      end.not_to raise_error

      expect { @list & 2 }.to raise_error(ArgumentError)
    end
  end

  describe '#at' do
    it 'works' do
      expect do
        cur = @list.cur_image
        img = @list.at(7)
        expect(@list[7]).to be(img)
        expect(@list.cur_image).to be(cur)
        img = @list.at(10)
        expect(img).to be(nil)
        expect(@list.cur_image).to be(cur)
        img = @list.at(-1)
        expect(@list[9]).to be(img)
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error
    end
  end

  describe '#star' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect do
        res = @list * 2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(20)
        expect(@list).not_to be(res)
        expect(res.cur_image).to be(cur)
      end.not_to raise_error

      expect { @list * 'x' }.to raise_error(ArgumentError)
    end
  end

  describe '#plus' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect do
        res = @list + @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(15)
        expect(@list).not_to be(res)
        expect(@list2).not_to be(res)
        expect(res.cur_image).to be(cur)
      end.not_to raise_error

      expect { @list + [2] }.to raise_error(ArgumentError)
    end
  end

  describe '#minus' do
    it 'works' do
      @list.scene = 0
      cur = @list.cur_image
      expect do
        res = @list - @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(5)
        expect(@list).not_to be(res)
        expect(@list2).not_to be(res)
        expect(res.cur_image).to be(cur)
      end.not_to raise_error

      # current scene not in result - set result scene to last image in result
      @list.scene = 7
      cur = @list.cur_image
      expect do
        res = @list - @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(5)
        expect(res.scene).to eq(4)
      end.not_to raise_error
    end
  end

  describe '#catenate' do
    it 'works' do
      expect do
        @list2.each { |img| @list << img }
        expect(@list.length).to eq(15)
        expect(@list.scene).to eq(14)
      end.not_to raise_error

      expect { @list << 2 }.to raise_error(ArgumentError)
      expect { @list << [2] }.to raise_error(ArgumentError)
    end
  end

  describe '#or' do
    it 'works' do
      expect do
        @list.scene = 7
        # The or of these two lists should be the same as @list
        # but not be the *same* list
        res = @list | @list2
        expect(res).to be_instance_of(Magick::ImageList)
        expect(@list).not_to be(res)
        expect(@list2).not_to be(res)
        expect(@list).to eq(res)
      end.not_to raise_error

      # Try or'ing disjoint lists
      temp_list = Magick::ImageList.new(*FILES[10..14])
      res = @list | temp_list
      expect(res).to be_instance_of(Magick::ImageList)
      expect(res.length).to eq(15)
      expect(res.scene).to eq(7)

      expect { @list | 2 }.to raise_error(ArgumentError)
      expect { @list | [2] }.to raise_error(ArgumentError)
    end
  end

  describe '#clear' do
    it 'works' do
      expect { @list.clear }.not_to raise_error
      expect(@list).to be_instance_of(Magick::ImageList)
      expect(@list.length).to eq(0)
      expect(@list.scene).to be(nil)
    end
  end

  describe '#collect' do
    it 'works' do
      expect do
        scene = @list.scene
        res = @list.collect(&:negate)
        expect(res).to be_instance_of(Magick::ImageList)
        expect(@list).not_to be(res)
        expect(res.scene).to eq(scene)
      end.not_to raise_error
      expect do
        scene = @list.scene
        @list.collect!(&:negate)
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list.scene).to eq(scene)
      end.not_to raise_error
    end
  end

  describe '#compact' do
    it 'works' do
      expect do
        res = @list.compact
        expect(@list).not_to be(res)
        expect(@list).to eq(res)
      end.not_to raise_error
      expect do
        res = @list
        @list.compact!
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list).to eq(res)
        expect(@list).to be(res)
      end.not_to raise_error
    end
  end

  describe '#concat' do
    it 'works' do
      expect do
        res = @list.concat(@list2)
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(15)
        expect(res.cur_image).to be(res[14])
      end.not_to raise_error
      expect { @list.concat(2) }.to raise_error(ArgumentError)
      expect { @list.concat([2]) }.to raise_error(ArgumentError)
    end
  end

  describe '#delete' do
    it 'works' do
      expect do
        cur = @list.cur_image
        img = @list[7]
        expect(@list.delete(img)).to be(img)
        expect(@list.length).to eq(9)
        expect(@list.cur_image).to be(cur)

        # Try deleting the current image.
        expect(@list.delete(cur)).to be(cur)
        expect(@list.cur_image).to be(@list[-1])

        expect { @list.delete(2) }.to raise_error(ArgumentError)
        expect { @list.delete([2]) }.to raise_error(ArgumentError)

        # Try deleting something that isn't in the list.
        # Should return the value of the block.
        expect do
          img = Magick::Image.read(FILES[10]).first
          res = @list.delete(img) { 1 }
          expect(res).to eq(1)
        end.not_to raise_error
      end.not_to raise_error
    end
  end

  describe '#delete_at' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect { @list.delete_at(9) }.not_to raise_error
      expect(@list.cur_image).to be(cur)
      expect { @list.delete_at(7) }.not_to raise_error
      expect(@list.cur_image).to be(@list[-1])
    end
  end

  describe '#delete_if' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect do
        @list.delete_if { |img| File.basename(img.filename) =~ /5/ }
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list.length).to eq(9)
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error

      # Delete the current image
      expect do
        @list.delete_if { |img| File.basename(img.filename) =~ /7/ }
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list.length).to eq(8)
        expect(@list.cur_image).to be(@list[-1])
      end.not_to raise_error
    end
  end

  # defined by Enumerable
  describe '#enumerables' do
    it 'works' do
      expect { @list.detect { true } }.not_to raise_error
      expect do
        @list.each_with_index { |img, _n| expect(img).to be_instance_of(Magick::Image) }
      end.not_to raise_error
      expect { @list.entries }.not_to raise_error
      expect { @list.include?(@list[0]) }.not_to raise_error
      expect { @list.inject(0) { 0 } }.not_to raise_error
      expect { @list.max }.not_to raise_error
      expect { @list.min }.not_to raise_error
      expect { @list.sort }.not_to raise_error
      expect { @list.sort_by(&:signature) }.not_to raise_error
      expect { @list.zip }.not_to raise_error
    end
  end

  describe '#eql?' do
    it 'works' do
      list2 = @list
      expect(@list.eql?(list2)).to be(true)
      list2 = @list.copy
      expect(@list.eql?(list2)).to be(false)
    end
  end

  describe '#fill' do
    it 'works' do
      list = @list.copy
      img = list[0].copy
      expect do
        expect(list.fill(img)).to be_instance_of(Magick::ImageList)
      end.not_to raise_error
      list.each { |el| expect(img).to be(el) }

      list = @list.copy
      list.fill(img, 0, 3)
      0.upto(2) { |i| expect(list[i]).to be(img) }

      list = @list.copy
      list.fill(img, 4..7)
      4.upto(7) { |i| expect(list[i]).to be(img) }

      list = @list.copy
      list.fill { |i| list[i] = img }
      list.each { |el| expect(img).to be(el) }

      list = @list.copy
      list.fill(0, 3) { |i| list[i] = img }
      0.upto(2) { |i| expect(list[i]).to be(img) }

      expect { list.fill('x', 0) }.to raise_error(ArgumentError)
    end
  end

  describe '#find' do
    it 'works' do
      expect { @list.find { true } }.not_to raise_error
    end
  end

  describe '#find_all' do
    it 'works' do
      expect do
        res = @list.select { |img| File.basename(img.filename) =~ /Button_2/ }
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(1)
        expect(@list[2]).to be(res[0])
      end.not_to raise_error
    end
  end

  describe '#insert' do
    it 'works' do
      expect do
        @list.scene = 7
        cur = @list.cur_image
        expect(@list.insert(1, @list[2])).to be_instance_of(Magick::ImageList)
        expect(@list.cur_image).to be(cur)
        @list.insert(1, @list[2], @list[3], @list[4])
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error

      expect { @list.insert(0, 'x') }.to raise_error(ArgumentError)
      expect { @list.insert(0, 'x', 'y') }.to raise_error(ArgumentError)
    end
  end

  describe '#last' do
    it 'works' do
      img = Magick::Image.new(5, 5)
      @list << img
      img2 = nil
      expect { img2 = @list.last }.not_to raise_error
      expect(img2).to be_instance_of(Magick::Image)
      expect(img).to eq(img2)
      img2 = Magick::Image.new(5, 5)
      @list << img2
      ilist = nil
      expect { ilist = @list.last(2) }.not_to raise_error
      expect(ilist).to be_instance_of(Magick::ImageList)
      expect(ilist.length).to eq(2)
      expect(ilist.scene).to eq(1)
      expect(ilist[0]).to eq(img)
      expect(ilist[1]).to eq(img2)
    end
  end

  describe '#__map__' do
    it 'works' do
      img = @list[0]
      expect do
        @list.__map__ { |_x| img }
      end.not_to raise_error
      expect(@list).to be_instance_of(Magick::ImageList)
      expect { @list.__map__ { 2 } }.to raise_error(ArgumentError)
    end
  end

  describe '#map!' do
    it 'works' do
      img = @list[0]
      expect do
        @list.map! { img }
      end.not_to raise_error
      expect(@list).to be_instance_of(Magick::ImageList)
      expect { @list.map! { 2 } }.to raise_error(ArgumentError)
    end
  end

  describe '#partition' do
    it 'works' do
      a = nil
      n = -1
      expect do
        a = @list.partition do
          n += 1
          (n & 1).zero?
        end
      end.not_to raise_error
      expect(a).to be_instance_of(Array)
      expect(a.size).to eq(2)
      expect(a[0]).to be_instance_of(Magick::ImageList)
      expect(a[1]).to be_instance_of(Magick::ImageList)
      expect(a[0].scene).to eq(4)
      expect(a[0].length).to eq(5)
      expect(a[1].scene).to eq(4)
      expect(a[1].length).to eq(5)
    end
  end

  describe '#pop' do
    it 'works' do
      @list.scene = 8
      cur = @list.cur_image
      last = @list[-1]
      expect do
        expect(@list.pop).to be(last)
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error

      expect(@list.pop).to be(cur)
      expect(@list.cur_image).to be(@list[-1])
    end
  end

  describe '#push' do
    it 'works' do
      list = @list
      img1 = @list[0]
      img2 = @list[1]
      expect { @list.push(img1, img2) }.not_to raise_error
      expect(@list).to be(list) # push returns self
      expect(@list.cur_image).to be(img2)
    end
  end

  describe '#reject' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      list = @list
      expect do
        res = @list.reject { |img| File.basename(img.filename) =~ /Button_9/ }
        expect(res.length).to eq(9)
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.cur_image).to be(cur)
      end.not_to raise_error
      expect(@list).to be(list)
      expect(@list.cur_image).to be(cur)

      # Omit current image from result list - result cur_image s/b last image
      res = @list.reject { |img| File.basename(img.filename) =~ /Button_7/ }
      expect(res.length).to eq(9)
      expect(res.cur_image).to be(res[-1])
      expect(@list.cur_image).to be(cur)
    end
  end

  describe '#reject!' do
    it 'works' do
      @list.scene = 7
      cur = @list.cur_image
      expect do
        @list.reject! { |img| File.basename(img.filename) =~ /5/ }
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list.length).to eq(9)
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error

      # Delete the current image
      expect do
        @list.reject! { |img| File.basename(img.filename) =~ /7/ }
        expect(@list).to be_instance_of(Magick::ImageList)
        expect(@list.length).to eq(8)
        expect(@list.cur_image).to be(@list[-1])
      end.not_to raise_error

      # returns nil if no changes are made
      expect(@list.reject! { false }).to be(nil)
    end
  end

  describe '#replace1' do
    it 'works' do
      # Replace with empty list
      expect do
        res = @list.replace([])
        expect(@list).to be(res)
        expect(@list.length).to eq(0)
        expect(@list.scene).to be(nil)
      end.not_to raise_error

      # Replace empty list with non-empty list
      temp = Magick::ImageList.new
      expect do
        temp.replace(@list2)
        expect(temp.length).to eq(5)
        expect(temp.scene).to eq(4)
      end.not_to raise_error

      # Try to replace with illegal values
      expect { @list.replace([1, 2, 3]) }.to raise_error(ArgumentError)
    end
  end

  describe '#replace2' do
    it 'works' do
      # Replace with shorter list
      expect do
        @list.scene = 7
        cur = @list.cur_image
        res = @list.replace(@list2)
        expect(@list).to be(res)
        expect(@list.length).to eq(5)
        expect(@list.scene).to eq(2)
        expect(@list.cur_image).to be(cur)
      end.not_to raise_error
    end
  end

  describe '#replace3' do
    it 'works' do
      # Replace with longer list
      expect do
        @list2.scene = 2
        cur = @list2.cur_image
        res = @list2.replace(@list)
        expect(@list2).to be(res)
        expect(@list2.length).to eq(10)
        expect(@list2.scene).to eq(7)
        expect(@list2.cur_image).to be(cur)
      end.not_to raise_error
    end
  end

  describe '#reverse' do
    it 'works' do
      list = nil
      cur = @list.cur_image
      expect { list = @list.reverse }.not_to raise_error
      expect(@list.length).to eq(list.length)
      expect(@list.cur_image).to be(cur)
    end
  end

  describe '#reverse!' do
    it 'works' do
      list = @list
      cur = @list.cur_image
      expect { @list.reverse! }.not_to raise_error
      expect(@list).to be(list)
      expect(@list.cur_image).to be(cur)
    end
  end

  # Just validate its existence
  describe '#reverse_each' do
    it 'works' do
      expect do
        @list.reverse_each { |img| expect(img).to be_instance_of(Magick::Image) }
      end.not_to raise_error
    end
  end

  describe '#rindex' do
    it 'works' do
      img = @list.last
      n = nil
      expect { n = @list.rindex(img) }.not_to raise_error
      expect(n).to eq(9)
    end
  end

  describe '#select' do
    it 'works' do
      expect do
        res = @list.select { |img| File.basename(img.filename) =~ /Button_2/ }
        expect(res).to be_instance_of(Magick::ImageList)
        expect(res.length).to eq(1)
        expect(@list[2]).to be(res[0])
      end.not_to raise_error
    end
  end

  describe '#shift' do
    it 'works' do
      expect do
        @list.scene = 0
        res = @list[0]
        img = @list.shift
        expect(img).to be(res)
        expect(@list.scene).to eq(8)
      end.not_to raise_error
      res = @list[0]
      img = @list.shift
      expect(img).to be(res)
      expect(@list.scene).to eq(7)
    end
  end

  describe '#slice' do
    it 'works' do
      expect { @list.slice(0) }.not_to raise_error
      expect { @list.slice(-1) }.not_to raise_error
      expect { @list.slice(0, 1) }.not_to raise_error
      expect { @list.slice(0..2) }.not_to raise_error
      expect { @list.slice(20) }.not_to raise_error
    end
  end

  describe '#slice!' do
    it 'works' do
      @list.scene = 7
      expect do
        img0 = @list[0]
        img = @list.slice!(0)
        expect(img).to be(img0)
        expect(@list.length).to eq(9)
        expect(@list.scene).to eq(6)
      end.not_to raise_error
      cur = @list.cur_image
      img = @list.slice!(6)
      expect(img).to be(cur)
      expect(@list.length).to eq(8)
      expect(@list.scene).to eq(7)
      expect { @list.slice!(-1) }.not_to raise_error
      expect { @list.slice!(0, 1) }.not_to raise_error
      expect { @list.slice!(0..2) }.not_to raise_error
      expect { @list.slice!(20) }.not_to raise_error
    end
  end

  # simply ensure existence
  describe '#sort' do
    it 'works' do
      expect { @list.sort }.not_to raise_error
      expect { @list.sort! }.not_to raise_error
    end
  end

  describe '#to_a' do
    it 'works' do
      a = nil
      expect { a = @list.to_a }.not_to raise_error
      expect(a).to be_instance_of(Array)
      expect(a.length).to eq(10)
    end
  end

  describe '#uniq' do
    it 'works' do
      expect { @list.uniq }.not_to raise_error
      expect(@list.uniq).to be_instance_of(Magick::ImageList)
      @list[1] = @list[0]
      @list.scene = 7
      list = @list.uniq
      expect(list.length).to eq(9)
      expect(list.scene).to eq(6)
      expect(@list.scene).to eq(7)
      @list[6] = @list[7]
      list = @list.uniq
      expect(list.length).to eq(8)
      expect(list.scene).to eq(5)
      expect(@list.scene).to eq(7)
    end
  end

  describe '#uniq!' do
    it 'works' do
      expect do
        expect(@list.uniq!).to be(nil)
      end.not_to raise_error
      @list[1] = @list[0]
      @list.scene = 7
      cur = @list.cur_image
      list = @list
      @list.uniq!
      expect(@list).to be(list)
      expect(@list.cur_image).to be(cur)
      expect(@list.scene).to eq(6)
      @list[5] = @list[6]
      @list.uniq!
      expect(@list.cur_image).to be(cur)
      expect(@list.scene).to eq(5)
    end
  end

  describe '#unshift' do
    it 'works' do
      img = @list[9]
      @list.scene = 7
      @list.unshift(img)
      expect(@list.scene).to eq(0)
      expect { @list.unshift(2) }.to raise_error(ArgumentError)
      expect { @list.unshift([1, 2]) }.to raise_error(ArgumentError)
    end
  end

  describe '#values_at' do
    it 'works' do
      ilist = nil
      expect { ilist = @list.values_at(1, 3, 5) }.not_to raise_error
      expect(ilist).to be_instance_of(Magick::ImageList)
      expect(ilist.length).to eq(3)
      expect(ilist.scene).to eq(2)
    end
  end

  describe '#spaceship' do
    it 'works' do
      list2 = @list.copy
      expect(list2.scene).to eq(@list.scene)
      expect(list2).to eq(@list)
      list2.scene = 0
      expect(list2).not_to eq(@list)
      list2 = @list.copy
      list2[9] = list2[0]
      expect(list2).not_to eq(@list)
      list2 = @list.copy
      list2 << @list[9]
      expect(list2).not_to eq(@list)

      expect { @list <=> 2 }.to raise_error(TypeError)
      list = Magick::ImageList.new
      list2 = Magick::ImageList.new
      expect { list2 <=> @list }.to raise_error(TypeError)
      expect { @list <=> list2 }.to raise_error(TypeError)
      expect { list <=> list2 }.not_to raise_error
    end
  end
end