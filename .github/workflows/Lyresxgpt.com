<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>LyresXGPT</title>
<style>
  body { font-family: Arial, sans-serif; background: #fff; margin:0; padding:0; }
  #chat { max-width: 700px; margin: 50px auto; border: 1px solid #ccc; padding: 20px; border-radius: 10px; height: 70vh; overflow-y: auto; }
  .message { padding:10px; margin:10px 0; border-radius: 10px; word-wrap: break-word; }
  .user { background: #e1f5fe; text-align:right; }
  .bot { background: #f1f1f1; text-align:left; }
  #inputArea { display:flex; margin-top:20px; max-width: 700px; margin-left:auto; margin-right:auto; }
  #inputArea input { flex:1; padding:10px; border-radius:5px; border:1px solid #ccc; }
  #inputArea button { padding:10px; margin-left:10px; border-radius:5px; border:none; background:#2196f3; color:#fff; cursor:pointer; }
</style>
</head>
<body>

<div id="chat">
  <div class="bot message">Merhaba! Ben LyresXGPT, ne hakkında konuşmak istersin?</div>
</div>

<div id="inputArea">
  <input type="text" id="userInput" placeholder="Mesajınızı yazın...">
  <button onclick="sendMessage()">Gönder</button>
  <button onclick="generateImage()">Görsel Üret</button>
</div>

<script>
const OPENAI_API_KEY = "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";

function addMessage(msg, sender) {
    const chat = document.getElementById('chat');
    const div = document.createElement('div');
    div.className = `${sender} message`;
    div.innerText = msg;
    chat.appendChild(div);
    chat.scrollTop = chat.scrollHeight;
}

async function sendMessage() {
    const input = document.getElementById('userInput');
    const message = input.value.trim();
    if(!message) return;
    addMessage(message, 'user');
    input.value = '';

    try {
        const response = await fetch("https://api.openai.com/v1/chat/completions", {
            method:"POST",
            headers: {
                "Content-Type":"application/json",
                "Authorization":`Bearer ${OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                model:"gpt-4o-mini",
                messages:[{role:"user", content: message}]
            })
        });
        const data = await response.json();
        if(!data.choices || !data.choices[0].message) {
            addMessage("Üzgünüm, şu an cevap veremiyorum.", 'bot');
            return;
        }
        const reply = data.choices[0].message.content;
        addMessage(reply, 'bot');

        const utter = new SpeechSynthesisUtterance(reply);
        utter.lang = 'tr-TR';
        speechSynthesis.speak(utter);
    } catch (err) {
        console.error(err);
        addMessage("API ile bağlantı kurulamadı.", 'bot');
    }
}

async function generateImage() {
    const userPrompt = window.prompt("Görsel için açıklama yazın:");
    if(!userPrompt) return;

    addMessage("Görsel üretiliyor...", 'bot');

    try {
        const response = await fetch("https://api.openai.com/v1/images/generations", {
            method:"POST",
            headers:{
                "Content-Type":"application/json",
                "Authorization": `Bearer ${OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                prompt: userPrompt,
                n:1,
                size:"512x512"
            })
        });
        const data = await response.json();
        if(!data.data || !data.data[0].url) {
            addMessage("Görsel üretilemedi.", 'bot');
            return;
        }
        const img_url = data.data[0].url;
        addMessage("Görsel hazır: " + img_url, 'bot');
    } catch (err) {
        console.error(err);
        addMessage("Görsel üretilemedi, bir hata oluştu.", 'bot');
    }
}
</script>

</body>
</html>
