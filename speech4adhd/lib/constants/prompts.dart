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
/// Phrased as statements so **Agree** / **Disagree** reads naturally.
const List<String> debateTopics = [
  'Hot pizza is better than cold pizza.',
  'Cats are better than dogs.',
  'Summer is better than winter.',
  'Homework should be banned.',
  'Reading is better than watching TV.',
  'Pizza is better than pasta.',
  'The moon is made of cheese.',
  'We should have dessert before dinner.',
  'Having one best friend is better than having lots of friends.',
  'A robot that cleans your room is better than a robot that does your homework.',
  'Breakfast is the best meal of the day.',
  'Every day should be a weekend.',
  'Dinosaurs are cooler than space.',
  'Being really tall is better than being really fast.',
  'Kids should choose what’s for dinner.',
  'Video games are a sport.',
  'Living in a treehouse is better than living in a castle.',
  'School should start later in the morning.',
  'Ice cream is better than cake.',
  'Exploring the ocean is better than exploring outer space.',
  'It’s okay to wear pajamas all day sometimes.',
  'Books are better than movies.',
  'Pets should be allowed at school.',
  'A messy room is a sign of creativity.',
  'Flying on a dragon is better than sailing a pirate ship.',
  'Friday is the best day of the week.',
  'There should be a national “silly hat” day every week.',
  'Building with LEGO is more fun than drawing.',
  'Robots will be our friends, not our bosses.',
  'Kids should pick their own bedtime on weekends.',
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
