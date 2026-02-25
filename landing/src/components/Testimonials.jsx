import React from 'react'
import { motion } from 'framer-motion'
import { Rocket, Briefcase, DollarSign, Smartphone, Shield, BarChart3, Check, User, HeadphonesIcon, Sparkles } from 'lucide-react'

const Testimonials = () => {
  const benefits = [
    {
      icon: Rocket,
      title: 'Быстрый старт',
      description: 'Запустите магазин за 5 минут. Всё готово к работе — просто добавьте товары.',
    },
    {
      icon: Briefcase,
      title: 'Без программирования',
      description: 'Удобная админ-панель. Управляйте всем через веб-интерфейс без технических знаний.',
    },
    {
      icon: DollarSign,
      title: 'Экономия средств',
      description: 'Не нужно нанимать разработчиков. Готовая платформа с оплатой и доставкой.',
    },
    {
      icon: Smartphone,
      title: 'Telegram интеграция',
      description: 'Ваши клиенты остаются в Telegram. Не нужно устанавливать отдельное приложение.',
    },
    {
      icon: Shield,
      title: 'Безопасность',
      description: 'Защищенные платежи через YooKassa. Валидация через Telegram init_data.',
    },
    {
      icon: BarChart3,
      title: 'Управление заказами',
      description: 'Отслеживайте все заказы в реальном времени. Меняйте статусы одним кликом.',
    },
  ]

  return (
    <section id="testimonials" className="py-20 bg-gradient-to-br from-slate-50 to-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Почему выбирают <span className="text-gradient">нас</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Преимущества платформы для вашего бизнеса
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {benefits.map((benefit, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-xl transition-all border border-gray-100"
            >
              <div className="w-12 h-12 bg-gradient-to-br from-slate-600 to-slate-800 rounded-xl flex items-center justify-center mb-4">
                <benefit.icon className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">
                {benefit.title}
              </h3>
              <p className="text-gray-600 leading-relaxed">
                {benefit.description}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Early Access CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="mt-16"
        >
          <div className="bg-white rounded-3xl shadow-2xl overflow-hidden border border-gray-200">
            <div className="bg-gradient-to-r from-slate-700 to-slate-900 px-8 py-6">
              <h3 className="text-3xl font-bold text-white mb-2 text-center">Станьте одним из первых</h3>
              <p className="text-slate-200 text-center max-w-2xl mx-auto">
                Присоединяйтесь к ранним пользователям и получите эксклюзивные преимущества
              </p>
            </div>
            <div className="p-8">
              <div className="grid md:grid-cols-3 gap-6">
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-slate-100 to-gray-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <User className="w-8 h-8 text-slate-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Персональный менеджер</h4>
                  <p className="text-sm text-gray-600">Выделенный специалист для решения ваших задач</p>
                </div>
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-slate-100 to-gray-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <HeadphonesIcon className="w-8 h-8 text-slate-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Приоритетная поддержка</h4>
                  <p className="text-sm text-gray-600">Быстрое решение вопросов в первую очередь</p>
                </div>
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-slate-100 to-gray-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <Sparkles className="w-8 h-8 text-slate-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Специальные условия</h4>
                  <p className="text-sm text-gray-600">Лучшие тарифы и индивидуальные предложения</p>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default Testimonials

