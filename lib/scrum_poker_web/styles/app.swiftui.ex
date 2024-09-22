defmodule ScrumPokerWeb.Styles.App.SwiftUI do
  use LiveViewNative.Stylesheet, :swiftui

  # A good read on Swift UI fonts and texts
  # https://www.swiftyplace.com/blog/swiftui-font-and-texts

  # Add your styles here
  # Refer to your client's documentation on what the proper syntax
  # is for defining rules within classes
  ~SHEET"""
  "page" do
    foregroundStyle(.black)
    background(Color(red: 0.79, green: 0.57, blue: 1.21))
  end

  "icon" do
    font(.title)
  end

  "card" do
    padding(35)
    font(.largeTitle)
  end

  "bg-unselected" do
    foregroundStyle(.black)
    background(.white)
    clipShape(.rect(cornerRadius: 15))
    shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
  end

  "bg-selected" do
    foregroundStyle(.white)
    background(.yellow)
    clipShape(.rect(cornerRadius: 15))
    shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
  end

  "title" do
    font(.headline)
    fontWeight(.bold)
    fontDesign(.monospaced)
    textCase(.uppercase)
  end

  "pad" do
    padding()
  end

  "button" do
    padding(.horizontal, 40)
    padding(.vertical, 10)
    background(.black)
    clipShape(.rect(cornerRadius: 40))
    textCase(.uppercase)
    fontWeight(.bold)
    foregroundStyle(.white)
  end

  "button:disabled" do
    background(.white)
  end

  "field" do
    padding(.vertical, 15)
    padding(.horizontal, 10)
    background(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.1))
    foregroundStyle(.black)
    clipShape(.rect(cornerRadius: 8))
  end

  "form" do
    padding(.vertical, 5)
    padding(.horizontal, 40)
  end

  "toggler" do
    tint(.black)
  end

  "footer" do
    font(.footnote)
    opacity(0.5)
  end

  "footer-icon" do
    foregroundStyle(.red)
    symbolEffect(.breathe.plain.wholeSymbol)
  end

  "user-list" do
    padding()
    background(.transparent)
    scrollContentBackground(.hidden)
  end

  "head" do
    padding()
  end

  "round-result" do
    font(.system(size: 50, weight: .bold, design: .rounded))
    lineSpacing(50)
    foregroundStyle(.yellow)
    padding(.horizontal, 20)
    symbolEffect(.bounce.down.wholeSymbol)
  end

  "status-icon" do
    font(.system(size: 12))
  end

  "voted" do
    foregroundStyle(.green)
  end

  "not-voted" do
    foregroundStyle(.red)
    opacity(0.5)
  end

  "loader" do
    symbolEffect(.bounce.up.wholeSymbol)
  end
  """



  # If you need to have greater control over how your style rules are created
  # you can use the function defintion style which is more verbose but allows
  # for more fine-grained controled
  #
  # This example shows what is not possible within the more concise ~SHEET
  # use `<Text class="frame:w100:h200" />` allows for a setting
  # of both the `width` and `height` values.

  # def class("frame:" <> dims) do
  #   [width] = Regex.run(~r/w(\d+)/, dims, capture: :all_but_first)
  #   [height] = Regex.run(~r/h(\d+)/, dims, capture: :all_but_first)

  #   ~RULES"""
  #   frame(width: {width}, height: {height})
  #   """
  # end
end
