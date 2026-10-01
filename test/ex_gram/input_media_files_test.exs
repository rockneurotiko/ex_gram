defmodule ExGram.InputMediaFilesTest do
  @moduledoc """
  Tests for file upload support in InputMedia parameters (send_media_group, edit_message_media, send_paid_media).
  """

  use ExUnit.Case, async: true

  alias ExGram.Model.InputMediaDocument
  alias ExGram.Model.InputMediaPhoto
  alias ExGram.Model.InputMediaVideo
  alias ExGram.Model.InputRichBlockCollage
  alias ExGram.Model.InputRichBlockDetails
  alias ExGram.Model.InputRichBlockPhoto
  alias ExGram.Model.InputRichBlockVideo
  alias ExGram.Model.InputRichMessage
  alias ExGram.Model.InputRichMessageMedia

  @token "test_token_123"

  setup {ExGram.Test, :verify_on_exit!}

  defp execute_send_media_group(media, opts \\ []) do
    chat_id = Keyword.get(opts, :chat_id, 123)

    ExGram.Test.expect(:send_media_group, %{"result" => []})

    ExGram.send_media_group!(chat_id, media, input_media: :media, token: @token)

    ExGram.Test.get_calls()
    |> List.last()
    |> elem(2)
  end

  defp execute_edit_message_media(media) do
    ExGram.Test.expect(:edit_message_media, %{"result" => true})

    ExGram.edit_message_media!(media, chat_id: 123, message_id: 456, token: @token)

    # Executer.execute_method(
    #   "editMessageMedia",
    #   :post,
    #   [media: media],
    #   [{:input_media, :media}],
    #   [Message, true],
    #   [adapter: TestAdapter, token: @token, check_params: false],
    #   [chat_id: 123, message_id: 456],
    #   [],
    #   []
    # )

    ExGram.Test.get_calls()
    |> List.last()
    |> elem(2)
  end

  defp execute_send_rich_message(rich_message) do
    ExGram.Test.expect(:send_rich_message, %{
      "result" => %{"message_id" => 1, "date" => 0, "chat" => %{"id" => 123, "type" => "private"}}
    })

    ExGram.send_rich_message!(123, rich_message, token: @token)

    ExGram.Test.get_calls()
    |> List.last()
    |> elem(2)
  end

  defp rich_message_part(parts) do
    {"rich_message", json} = Enum.find(parts, &match?({"rich_message", _}, &1))
    Jason.decode!(json)
  end

  describe "send_media_group with file uploads" do
    test "produces multipart body when InputMedia contains {:file, path}" do
      media = [
        %InputMediaPhoto{type: "photo", media: {:file, "/tmp/photo1.jpg"}},
        %InputMediaPhoto{type: "photo", media: {:file, "/tmp/photo2.jpg"}}
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      # Should have file parts for both photos
      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 2

      assert {:file, "media_0_media", "/tmp/photo1.jpg"} in file_parts
      assert {:file, "media_1_media", "/tmp/photo2.jpg"} in file_parts

      # The media field should be JSON-encoded with attach:// references
      media_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "media"
          _ -> false
        end)

      assert {_, media_json} = media_part
      decoded = Jason.decode!(media_json)
      assert [first, second] = decoded
      assert first["media"] == "attach://media_0_media"
      assert second["media"] == "attach://media_1_media"
      assert first["type"] == "photo"
      assert second["type"] == "photo"
    end

    test "returns plain body when InputMedia contains only strings (file_ids/URLs)" do
      media = [
        %InputMediaPhoto{type: "photo", media: "AgACAgIAA_file_id_1"},
        %InputMediaPhoto{type: "photo", media: "https://example.com/photo.jpg"}
      ]

      body = execute_send_media_group(media)

      # No files to upload, so body should be a plain map (not multipart)
      assert is_map(body)
      refute match?({:multipart, _}, body)
      assert body[:chat_id] == 123
    end

    test "handles mixed file uploads and URLs" do
      media = [
        %InputMediaPhoto{type: "photo", media: {:file, "/tmp/local.jpg"}, caption: "Local file"},
        %InputMediaPhoto{
          type: "photo",
          media: "https://example.com/remote.jpg",
          caption: "Remote URL"
        }
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 1
      assert {:file, "media_0_media", "/tmp/local.jpg"} in file_parts

      media_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "media"
          _ -> false
        end)

      {_, media_json} = media_part
      decoded = Jason.decode!(media_json)
      assert [first, second] = decoded
      assert first["media"] == "attach://media_0_media"
      assert first["caption"] == "Local file"
      assert second["media"] == "https://example.com/remote.jpg"
      assert second["caption"] == "Remote URL"
    end

    test "handles {:file_content, content, filename} tuples" do
      media = [
        %InputMediaPhoto{
          type: "photo",
          media: {:file_content, "fake_image_data", "photo.jpg"}
        }
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      file_content_parts = Enum.filter(parts, &match?({:file_content, _, _, _}, &1))
      assert length(file_content_parts) == 1

      assert {:file_content, "media_0_media", "fake_image_data", "photo.jpg"} in file_content_parts

      media_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "media"
          _ -> false
        end)

      {_, media_json} = media_part
      [decoded_item] = Jason.decode!(media_json)
      assert decoded_item["media"] == "attach://media_0_media"
    end

    test "handles thumbnail file uploads on InputMediaVideo" do
      media = [
        %InputMediaVideo{
          type: "video",
          media: {:file, "/tmp/video.mp4"},
          thumbnail: {:file, "/tmp/thumb.jpg"}
        }
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 2
      assert {:file, "media_0_media", "/tmp/video.mp4"} in file_parts
      assert {:file, "media_0_thumbnail", "/tmp/thumb.jpg"} in file_parts

      media_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "media"
          _ -> false
        end)

      {_, media_json} = media_part
      [decoded_item] = Jason.decode!(media_json)
      assert decoded_item["media"] == "attach://media_0_media"
      assert decoded_item["thumbnail"] == "attach://media_0_thumbnail"
    end

    test "handles cover file uploads on InputMediaVideo" do
      media = [
        %InputMediaVideo{
          type: "video",
          media: {:file, "/tmp/video.mp4"},
          cover: {:file, "/tmp/cover.jpg"}
        }
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 2
      assert {:file, "media_0_media", "/tmp/video.mp4"} in file_parts
      assert {:file, "media_0_cover", "/tmp/cover.jpg"} in file_parts
    end

    test "handles InputMediaDocument with file uploads" do
      media = [
        %InputMediaDocument{
          type: "document",
          media: {:file, "/tmp/doc.pdf"},
          thumbnail: {:file, "/tmp/doc_thumb.jpg"}
        }
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 2
      assert {:file, "media_0_media", "/tmp/doc.pdf"} in file_parts
      assert {:file, "media_0_thumbnail", "/tmp/doc_thumb.jpg"} in file_parts
    end

    test "preserves chat_id and other parameters in multipart body" do
      media = [
        %InputMediaPhoto{type: "photo", media: {:file, "/tmp/photo.jpg"}}
      ]

      body = execute_send_media_group(media)

      assert {:multipart, parts} = body

      chat_id_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "chat_id"
          _ -> false
        end)

      assert {"chat_id", "123"} = chat_id_part
    end
  end

  describe "send_rich_message with file uploads" do
    test "uploads files from media blocks nested at any depth" do
      rich_message = %InputRichMessage{
        blocks: [
          %InputRichBlockVideo{type: "video", video: %InputMediaVideo{type: "video", media: {:file, "/tmp/video.mp4"}}},
          %InputRichBlockCollage{
            type: "collage",
            blocks: [
              %InputRichBlockPhoto{
                type: "photo",
                photo: %InputMediaPhoto{type: "photo", media: {:file_content, "data", "a.jpg"}}
              },
              %InputRichBlockPhoto{type: "photo", photo: %InputMediaPhoto{type: "photo", media: "AgACAgIAA_file_id"}}
            ]
          },
          %InputRichBlockDetails{
            type: "details",
            summary: "More",
            blocks: [
              %InputRichBlockPhoto{type: "photo", photo: %InputMediaPhoto{type: "photo", media: {:file, "/tmp/b.jpg"}}}
            ]
          }
        ]
      }

      assert {:multipart, parts} = execute_send_rich_message(rich_message)

      assert {:file, "rich_message_0_media", "/tmp/video.mp4"} in parts
      assert {:file_content, "rich_message_1_media", "data", "a.jpg"} in parts
      assert {:file, "rich_message_2_media", "/tmp/b.jpg"} in parts

      assert %{"blocks" => [video, collage, details]} = rich_message_part(parts)
      assert video["video"]["media"] == "attach://rich_message_0_media"

      assert [
               %{"photo" => %{"media" => "attach://rich_message_1_media"}},
               %{"photo" => %{"media" => "AgACAgIAA_file_id"}}
             ] =
               collage["blocks"]

      assert [%{"photo" => %{"media" => "attach://rich_message_2_media"}}] = details["blocks"]
    end

    test "uploads files from the media list and its thumbnails" do
      rich_message = %InputRichMessage{
        html: ~s(<video src="tg://video?id=clip"/>),
        media: [
          %InputRichMessageMedia{
            id: "clip",
            media: %InputMediaVideo{
              type: "video",
              media: {:file, "/tmp/clip.mp4"},
              thumbnail: {:file, "/tmp/thumb.jpg"}
            }
          }
        ]
      }

      assert {:multipart, parts} = execute_send_rich_message(rich_message)

      assert {:file, "rich_message_0_media", "/tmp/clip.mp4"} in parts
      assert {:file, "rich_message_0_thumbnail", "/tmp/thumb.jpg"} in parts

      assert %{"media" => [%{"id" => "clip", "media" => media}]} = rich_message_part(parts)
      assert media["media"] == "attach://rich_message_0_media"
      assert media["thumbnail"] == "attach://rich_message_0_thumbnail"
    end

    test "returns plain body when rich message media are file_ids or URLs" do
      rich_message = %InputRichMessage{
        blocks: [
          %InputRichBlockPhoto{type: "photo", photo: %InputMediaPhoto{type: "photo", media: "AgACAgIAA_file_id"}},
          %InputRichBlockVideo{
            type: "video",
            video: %InputMediaVideo{type: "video", media: "https://example.com/v.mp4"}
          }
        ]
      }

      body = execute_send_rich_message(rich_message)

      assert is_map(body)
      refute match?({:multipart, _}, body)

      assert %{blocks: [%{photo: %{media: "AgACAgIAA_file_id"}}, %{video: %{media: "https://example.com/v.mp4"}}]} =
               body[:rich_message]
    end
  end

  describe "edit_message_media with file uploads" do
    test "produces multipart body for single InputMedia with file" do
      media = %InputMediaPhoto{type: "photo", media: {:file, "/tmp/new_photo.jpg"}}

      body = execute_edit_message_media(media)

      assert {:multipart, parts} = body

      file_parts = Enum.filter(parts, &match?({:file, _, _}, &1))
      assert length(file_parts) == 1
      assert {:file, "media_0_media", "/tmp/new_photo.jpg"} in file_parts

      media_part =
        Enum.find(parts, fn
          {name, _} when is_binary(name) -> name == "media"
          _ -> false
        end)

      {_, media_json} = media_part
      decoded = Jason.decode!(media_json)
      assert decoded["media"] == "attach://media_0_media"
      assert decoded["type"] == "photo"
    end

    test "returns plain body when InputMedia has string media (file_id)" do
      media = %InputMediaPhoto{type: "photo", media: "AgACAgIAA_file_id"}

      body = execute_edit_message_media(media)

      assert is_map(body)
      refute match?({:multipart, _}, body)
    end
  end
end
