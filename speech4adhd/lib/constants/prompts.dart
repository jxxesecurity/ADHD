import 'dart:math';

/// Fun talking prompts for kids with ADHD (ages 6–14).
/// Short, exciting, open-ended — for communication practice only (no language learning).

const List<String> talkingPrompts = [
  'Tell me about your favorite game!',
  'What would you do if you had superpowers?',
  'Describe your dream pet!',
  'Would you rather fly or be invisible? Why?',
  'Tell a 30-second story about a silly monster!',
  'What is the coolest thing you did this week?',
  'If you could have dinner with any character, who and why?',
  'What makes you laugh the most?',
  'Describe the best birthday party ever!',
  'If you invented a new candy, what would it be?',
  'What is your favorite thing to do outside?',
  'Tell me about your best friend in three sentences!',
  'Would you rather have a dragon or a unicorn? Why?',
  'What is the funniest thing that ever happened to you?',
  'If you could go anywhere for one day, where?',
  'What is your favorite thing about school?',
  'Describe a super-silly superhero and their power!',
  'What would you do if you were principal for a day?',
  'Tell me about your favorite animal and why you love it!',
  'If you could make one rule everyone had to follow, what would it be?',
  'What is the best present you ever got?',
  'Describe your dream treehouse!',
  'What would you name a new planet?',
  'Tell me about a time you felt really proud!',
  'If you could have any job when you grow up, what and why?',
  'What is your favorite thing to build or create?',
  'Describe the perfect Saturday!',
  'What would you do if you found a magic lamp?',
  'Tell me about your favorite place in the world!',
  'If you could talk to animals, which one would you chat with first?',
];

/// Simple, silly debate topics for kids (short turns — keep it fun).
const List<String> debateTopics = [
  'Is pizza better hot or cold?',
  'Cats vs. dogs — which is better?',
  'Is summer better than winter?',
  'Should homework be banned?',
  'Is reading better than watching TV?',
  'Pizza or pasta — which wins?',
  'Is the moon made of cheese? (Yes or no — and why!)',
  'Should we have dessert before dinner?',
  'Is it better to have one best friend or lots of friends?',
  'Would you rather have a robot that cleans your room or does your homework?',
  'Is breakfast the best meal of the day?',
  'Should every day be a weekend?',
  'Are dinosaurs cooler than space?',
  'Is it better to be really tall or really fast?',
  'Should kids choose what’s for dinner?',
  'Are video games a sport?',
  'Is it better to live in a treehouse or a castle?',
  'Should school start later in the morning?',
  'Ice cream or cake — which is the real champion?',
  'Would you rather explore the ocean or outer space?',
  'Is it okay to wear pajamas all day sometimes?',
  'Are books better than movies?',
  'Should pets be allowed at school?',
  'Is a messy room a sign of creativity?',
  'Would you rather fly on a dragon or sail a pirate ship?',
  'Is Friday the best day of the week?',
  'Should there be a national “silly hat” day every week?',
  'Is it more fun to build with LEGO or draw?',
  'Are robots going to be our friends or our bosses?',
  'Should kids pick their own bedtime on weekends?',
];

/// Picks a random debate topic, avoiding [avoid] when possible (no repeat twice in a row).
String pickDebateTopic(Random random, {String? avoid}) {
  if (debateTopics.isEmpty) return '';
  if (debateTopics.length == 1) return debateTopics[0];
  String picked;
  var tries = 0;
  do {
    picked = debateTopics[random.nextInt(debateTopics.length)];
    tries++;
  } while (avoid != null && picked == avoid && tries < 64);
  return picked;
}
