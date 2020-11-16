defmodule CdcBooks.Mogrify do
  def blur_image(path) do
    %Mogrify.Image{path: newpath} =
      Mogrify.open(path)
      |> Mogrify.format("jpg")
      |> Mogrify.custom("colorspace", "Gray")
      |> Mogrify.resize("400x400>")
      |> Mogrify.add_option(Mogrify.Options.Filter.option_gaussian_blur("4x4"))
      |> Mogrify.save(path: "#{path}_blur.jpg")

    newpath
  end
end
