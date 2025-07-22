const { Client, GatewayIntentBits } = require('discord.js');
const fs = require('fs');
const mysql = require('mysql2/promise');
const config = require('./config.json');

const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages] });

let db;

async function getLeaderboardRows() {
  try {
    const [rows] = await db.query(`
      SELECT firstname, lastname,
             JSON_UNQUOTE(JSON_EXTRACT(accounts, '$.money')) as money,
             JSON_UNQUOTE(JSON_EXTRACT(accounts, '$.bank')) as bank,
             JSON_UNQUOTE(JSON_EXTRACT(accounts, '$."black_money"')) as black_money
      FROM users
      ORDER BY (CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, '$.money')) AS UNSIGNED) +
                CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, '$.bank')) AS UNSIGNED) +
                CAST(JSON_UNQUOTE(JSON_EXTRACT(accounts, '$."black_money"')) AS UNSIGNED)) DESC
      LIMIT 10
    `);

    return rows.map((row, index) => {
      const total = (parseInt(row.money) || 0) + (parseInt(row.bank) || 0) + (parseInt(row.black_money) || 0);
      const name = `${row.firstname} ${row.lastname}`;
      return `**${index + 1}.** ${name} - 💲 \`${total}\``;
    });
  } catch (err) {
    console.error("❌ MySQL error:", err);
    return ['⚠️ Failed to fetch data.'];
  }
}

client.once('ready', async () => {
  console.log(`✅ Logged in as ${client.user.tag}`);

  db = await mysql.createConnection(config.mysql);

  const channel = await client.channels.fetch(config.channelId);
  if (!channel || !channel.isTextBased()) return console.error("❌ Invalid channel");

  let targetMessage = null;

  if (config.messageId && config.messageId !== "LEAVE_EMPTY_FIRST_RUN") {
    try {
      targetMessage = await channel.messages.fetch(config.messageId);
    } catch (err) {
      console.warn("⚠️ Could not fetch existing message. Creating new one...");
    }
  }

  setInterval(async () => {
    const leaderboard = await getLeaderboardRows();
    const content = `**💰 Top Richest Players Leaderboard**\n\n${leaderboard.join("\n")}\n\n_Last updated: <t:${Math.floor(Date.now() / 1000)}:R>_`;

    if (!targetMessage) {
      targetMessage = await channel.send(content);
      config.messageId = targetMessage.id;
      fs.writeFileSync('./config.json', JSON.stringify(config, null, 2));
      console.log("✅ Sent initial leaderboard message");
    } else {
      await targetMessage.edit(content);
      console.log("🔁 Updated leaderboard");
    }
  }, config.updateInterval);
});

client.login(config.token);
